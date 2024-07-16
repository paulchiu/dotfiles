#!/usr/bin/env zx

cd('/Users/paul/dev')

echo("Updating mr-yum-db-schema...")
cd('mr-yum-db-schema')
await $`git reset HEAD --hard`
await $`git fetch --all -p`
await $`git checkout main`
await $`git pull origin main`
await $`make migrate`

echo("Done!")