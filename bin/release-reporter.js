#!/usr/bin/env node

// @ts-check

// ------------------------------------------------------------
// Config
// ------------------------------------------------------------

// @ts-ignore
const API_TOKEN = process.env.BUILDKITE_API_TOKEN;
const ORGANIZATION = process.env.BUILDKITE_ORGANIZATION || "mryum";
const API_URL = `https://api.buildkite.com/v2/organizations/${ORGANIZATION}/pipelines`;
const PAGE = "1";
const PER_PAGE = "20";

// ------------------------------------------------------------
// Functions
// ------------------------------------------------------------

/**
 * @typedef {Object} Author
 * @property {String} name
 *
 * @typedef {Object} Build
 * @property {String} message
 * @property {String} state
 * @property {boolean} blocked
 * @property {Author} author
 *
 * @typedef {Error & { pipeline?: String, branch?: String }} PipelineNotFoundError
 */

/**
 * @param {String} pipeline
 * @param {String} branch
 * @returns PipelineNotFoundError
 */
function createPipelineNotFoundError(pipeline, branch) {
  /** @type {PipelineNotFoundError} */
  const error = new Error(
    `Buildkite pipeline not found: ${pipeline} (${branch})`
  );
  error.name = "PipelineNotFoundError";
  error.pipeline = pipeline;
  error.branch = branch;
  return error;
}

/**
 * @param {String} pipeline
 * @param {String} branch
 * @returns String
 */
function getBuildsUrl(pipeline, branch) {
  const url = new URL(`${API_URL}/${encodeURIComponent(pipeline)}/builds`);
  url.searchParams.set("branch", branch);
  url.searchParams.set("page", PAGE);
  url.searchParams.set("per_page", PER_PAGE);

  return url.toString();
}

/**
 * @param {String} body
 * @returns String
 */
function getErrorBodySnippet(body) {
  if (!body) {
    return "";
  }

  return `: ${body.substring(0, 500)}`;
}

/**
 * @param {String} pipeline
 * @param {String} branch
 * @returns Promise<Build[]>
 *
 */
async function fetchBuilds(pipeline, branch) {
  const response = await fetch(getBuildsUrl(pipeline, branch), {
    headers: {
      Authorization: `Bearer ${API_TOKEN}`,
    },
  });

  if (!response.ok) {
    if (response.status === 404) {
      throw createPipelineNotFoundError(pipeline, branch);
    }

    const body = await response.text();
    throw new Error(
      `Buildkite API error for ${pipeline} (${branch}): HTTP ${
        response.status
      }${getErrorBodySnippet(body)}`
    );
  }

  return await response.json();
}

/**
 * @param {Build} build
 * @returns boolean
 */
function needsRelease(build) {
  return ["failed", "running"].includes(build.state) || build.blocked === true;
}

/**
 * @param {Build[]} builds
 * @returns Build[]
 */
function getReleaseBuilds(builds) {
  let blockedBuilds = [];

  for (let build of builds) {
    if (needsRelease(build)) {
      blockedBuilds.push(build);
    } else {
      break;
    }
  }

  return blockedBuilds;
}

/**
 * @param {Build} build
 * @returns String
 */
function buildToReleaseNoteMapper(build) {
  const message = build.message.replace(/\@/g, "@ ");
  return `${getFirstLine(message)} *by ${build?.author?.name || "(unknown)"}*`;
}

/**
 * @param {String} text
 * @returns String
 */
function getFirstLine(text) {
  /** @type {number | undefined} */
  var index = text.indexOf("\n");

  if (index === -1) {
    index = undefined;
  }

  return text.substring(0, index);
}

/**
 * @typedef {String} Pipeline
 * @typedef {String} Branch
 * @typedef {[Pipeline, Branch]} PipelineTuple
 *
 * @typedef {Object} PipelineBuilds
 * @property {String} pipeline
 * @property {Build[]} builds
 * @property {number} number
 * @property {String} url
 *
 * @param {PipelineTuple[]} pipelineTuples
 * @returns Promise<PipelineBuilds[]>
 */
async function getPipelinesBuilds(pipelineTuples) {
  const pipelineBuilds = await Promise.all(
    pipelineTuples.map(async (pipelineTuple) => {
      const [pipeline, branch] = pipelineTuple;
      let builds;

      try {
        builds = await fetchBuilds(pipeline, branch);
      } catch (error) {
        if (error?.name === "PipelineNotFoundError") {
          console.warn(
            `Skipping missing Buildkite pipeline: ${pipeline} (${branch})`
          );
          return undefined;
        }

        throw error;
      }

      if (builds.length === 0) {
        return undefined;
      }

      const releaseBuild = builds[0];
      const { number, web_url: url } = releaseBuild;

      return {
        pipeline,
        builds,
        number,
        url,
      };
    })
  );

  const existingPipelineBuilds = /** @type {PipelineBuilds[]} */ (
    pipelineBuilds.filter((b) => !!b)
  );

  if (existingPipelineBuilds.length === 0 && pipelineTuples.length > 0) {
    throw new Error(
      `No Buildkite pipelines could be fetched for organization ${ORGANIZATION}. Check BUILDKITE_API_TOKEN and BUILDKITE_ORGANIZATION.`
    );
  }

  return existingPipelineBuilds;
}

/**
 * @param {PipelineBuilds} build
 * @returns String
 */
function getBuildItemLink(build) {
  return `[${build.number}](${build.url})`;
}

/**
 * @param {PipelineBuilds[]} pipelinesBuilds
 * @returns String
 */
function convertToMarkdownList(pipelinesBuilds) {
  let markdown = "";

  pipelinesBuilds.forEach((pipelineBuilds) => {
    const releaseBuilds = getReleaseBuilds(pipelineBuilds.builds);
    const releaseNotes = releaseBuilds.map(buildToReleaseNoteMapper);

    if (releaseNotes.length === 0) {
      return;
    }

    markdown += `- \`${pipelineBuilds.pipeline}\` build ${getBuildItemLink(
      pipelineBuilds
    )}`;

    if (releaseNotes.length === 1) {
      markdown += `, ${releaseNotes[0]}\n`;
      return;
    }

    markdown += ":\n";
    releaseNotes.forEach((note) => {
      markdown += `    - ${note}\n`;
    });
  });

  return markdown;
}

/**
 * @returns String
 */
function getReleaseDate() {
  let today = new Date();
  /** @type {Intl.DateTimeFormatOptions} */
  let options = {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  };
  return today.toLocaleDateString("en-US", options);
}

/**
 * @param {number} minutes
 * @param {number} base
 * @returns number
 */
function roundMinutesToNearestBase(minutes, base) {
  return Math.round(minutes / base) * base;
}

/**
 * @param {Date} date
 * @returns String
 */
function getReadableTime(date) {
  if (date.getMinutes() < 10) {
    return `${date.getHours()}:0${date.getMinutes()}`;
  }

  return `${date.getHours()}:${date.getMinutes()}`;
}

/**
 * @param {number} minutesInFuture
 * @param {number} minutesToRoundTo
 * @returns String
 */
function getNextClosest(minutesInFuture, minutesToRoundTo) {
  const releaseTimeLocal = new Date();
  releaseTimeLocal.setMinutes(releaseTimeLocal.getMinutes() + minutesInFuture);
  releaseTimeLocal.setMinutes(
    roundMinutesToNearestBase(releaseTimeLocal.getMinutes(), minutesToRoundTo)
  );

  const releaseTimeMelbourne = new Date(releaseTimeLocal.getTime());
  releaseTimeMelbourne.setHours(releaseTimeMelbourne.getHours() + 1);

  const dayLightSavings = true;

  if (dayLightSavings) {
    return `${getReadableTime(releaseTimeLocal)} AEST / ${getReadableTime(
      releaseTimeMelbourne
    )} AEDT`;
  } else {
    return `${getReadableTime(releaseTimeLocal)} AEST/AEDT`;
  }
}

/**
 * @param {PipelineTuple[]} pipelines
 */
async function logReleaseNotes(pipelines) {
  if (!API_TOKEN) {
    throw new Error("BUILDKITE_API_TOKEN is required.");
  }

  const pipelinesBuilds = await getPipelinesBuilds(pipelines);
  console.log(`### ctrl-alt-delight releases for ${getReleaseDate()}`);
  console.log("");
  console.log(convertToMarkdownList(pipelinesBuilds));
  console.log(
    `Will :big-red-button: in approx. 30mins at ${getNextClosest(
      30,
      15
    )} if no objections.`
  );
}

// ------------------------------------------------------------
// Main program
// ------------------------------------------------------------

logReleaseNotes([
  ["cloudflare-workers", "main"],
  ["guest-gateway", "main"],
  ["manage-api", "main"],
  ["manage-frontend", "main"],
  ["mr-yum", "master"],
  ["mr-yum-deploy", "staging"],
  ["serve-api", "main"],
  ["serve-frontend", "main"],
  ["stable-api", "main"],
  ["pos-integrations", "main"],
]).catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
