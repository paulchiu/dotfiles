#!/usr/bin/env zx

cd("/Users/paul/dev");

// List of folders to pull and their main branch
const folders = [
  "guest-gateway",
  "manage-api",
  "manage-frontend",
  "menu-api",
  "menu-cache-detector",
  "menu-cache-generator",
  "mr-yum",
  "order-api",
  "serve-api",
  "serve-frontend",
];

const confirmApplicable = async (folder) => {
  within(async () => {
    try {
      cd(folder);
      await $`ag node:18-alpine3.18`;
      echo(`${folder} is using alpine 3.18 with Node 18`);
      await $`echo '${folder} is using alpine 3.18 with Node 18' >> /Users/paul/Downloads/results.txt`;
    } catch (e) {
      echo(`${folder} is not applicable`);
    }
  });
};

const applyChanges = async (folder) => {
  within(async () => {
    try {
      cd(folder);
      await $`ag node:18-alpine3.18`;
      await $`sed -i '' 's/node:18-alpine3.18/node:18-alpine3.16/g' Dockerfile`;
      await $`git checkout -b feature/srv-2386-all-repos-use-alpine-316-with-node-18`;
      await $`git add .`;
      await $`git commit -m "[SRV-2386] fix(Dockerfile): Use Alpine 3.16 with Node 18"`;
      await $`git push`;
      await $`gh pr create --title "[SRV-2386] fix(Dockerfile): Use Alpine 3.16 with Node 18" --body "This PR was automatically created by a script. Please review and merge." --base main --head feature/srv-2386-all-repos-use-alpine-316-with-node-18`;
    } catch (e) {
      echo(`Error ${e} in ${folder}`);
    }
  });
};

echo("Running repo script on all repos...");
const repoScripts = folders.map(confirmApplicable);
await Promise.all(repoScripts);

echo("Done!");
