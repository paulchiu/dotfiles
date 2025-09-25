#!/bin/zsh

set -e

# Log out just incase on dev account
aws sso logout

# Login as super admin
mryum aws login --profile=super-admin
mryum aws eks --profile=super-admin
mryum shell --profile=super-admin
