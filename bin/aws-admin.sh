#!/bin/zsh

set -e

# Log out just incase on dev account
aws sso logout

# Login as super admin
mryum aws login --profile=super-admin
mryum aws eks --profile=super-admin
# Don't know why below don't work
# mryum shell --profile=super-admin

echo '⁉️⚠️ℹ️ MUST RUN BELOW MANUALLY'
echo '-----------------------------'
echo 'eval $(mryum export --profile=super-admin)'
