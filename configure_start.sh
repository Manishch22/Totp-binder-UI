#!/bin/bash

#installs the pre-requisites.
set -e

workingDir=$nginx_dir/html
if [ -z "$TOTP_BINDER_UI_PUBLIC_URL" ]; then
  rpCmd="s/_PUBLIC_URL_//g"
  grep -rl '_PUBLIC_URL_' $workingDir | xargs sed -i $rpCmd
else
  workingDir=$nginx_dir/${TOTP_BINDER_UI_PUBLIC_URL}
  mkdir $workingDir
  mv  -v $nginx_dir/html/* $workingDir/
  rpCmd="s/_PUBLIC_URL_/\/${TOTP_BINDER_UI_PUBLIC_URL}/g"
  grep -rl '_PUBLIC_URL_' $workingDir | xargs sed -i $rpCmd
fi

echo "Replacing completed."

echo "generating env-config file"

echo "window._env_ = {" > ${workingDir}/env-config.js
awk -F '=' '{ print $1 ": \"" (ENVIRON[$1] ? ENVIRON[$1] : $2) "\"," }' ${workingDir}/env.env >> ${workingDir}/env-config.js
echo "}" >> ${workingDir}/env-config.js

echo "generation of env-config file completed!"

exec "$@"
