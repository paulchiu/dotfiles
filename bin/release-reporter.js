#!/usr/bin/env node

// @ts-check

// ------------------------------------------------------------
// Config
// ------------------------------------------------------------

// @ts-ignore
const API_TOKEN = process.env.BUILDKITE_API_TOKEN;
const API_URL = "https://api.buildkite.com/v2/organizations/mryum/pipelines";
const PAGE_PARAMS = "page=1&per_page=20";

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
 * @param {String} pipeline
 * @param {String} branch
 * @returns Build
 */
async function fetchBuilds(pipeline, branch) {
  const response = await fetch(
    `${API_URL}/${pipeline}/builds?branch=${branch}&${PAGE_PARAMS}`,
    {
      headers: {
        Authorization: `Bearer ${API_TOKEN}`,
      },
    }
  );

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
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
 * @property {Object[]} builds
 * @property {number} number
 * @property {String} url
 *
 * @param {PipelineTuple[]} pipelineTuples
 * @returns PipelineBuilds[]
 */
async function getPipelinesBuilds(pipelineTuples) {
  const pipelineBuilds = await Promise.all(
    pipelineTuples.map(async (pipelineTuple) => {
      const [pipeline, branch] = pipelineTuple;
      const builds = await fetchBuilds(pipeline, branch);
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

  return pipelineBuilds;
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
  ["beamer", "main"],
  ["cloudflare-workers", "main"],
  ["guest-gateway", "main"],
  ["manage-api", "main"],
  ["manage-frontend", "main"],
  ["mr-yum", "master"],
  ["mr-yum-deploy", "staging"],
  ["serve-api", "main"],
  ["serve-frontend", "main"],
  // ['db-tasks', 'main'],
]);
