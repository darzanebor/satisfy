#!/usr/bin/env bash
set -xe

GENERATED_SECRET="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
PARAM_FILE="${APP_ROOT}/config/parameters.yml"
SATIS_FILE="${APP_ROOT}/satis.json"
SECRET=${SECRET:-$GENERATED_SECRET}
REPO_NAME=${REPO_NAME:-"myrepo/composer-mirror"}
HOMEPAGE=${HOMEPAGE:-"http://localhost:8080"}
APP_USER_HOME=${APP_USER_HOME:-$HOME}
CRON_ENABLED=${CRON_ENABLED:-true}
CRON_SYNC_EVERY=${CRON_SYNC_EVERY:=300}


if [ ! -f "${PARAM_FILE}" ]; then
  cat >${PARAM_FILE} <<EOF
parameters:
  secret: "${SECRET}"
  satis_filename: "%kernel.project_dir%/satis.json"
  satis_log_path: "%kernel.project_dir%/var/satis"
  admin.auth: ${ADMIN_AUTH:-"false"}
  admin.users: ${ADMIN_USERS:-"[]"}
  composer.home: "${APP_USER_HOME}/.composer"
EOF
  chown ${APP_USER}:${APP_USER} ${PARAM_FILE}
fi

if [ ! -f "${SATIS_FILE}" ]; then
  cat >${SATIS_FILE} <<EOF
{
    "name": "${REPO_NAME}",
    "homepage": "${HOMEPAGE}",
    "repositories": [
    ],
    "require-all": true,
    "providers": true,
    "archive": {
        "directory": "dist",
        "format": "zip",
        "skip-dev": false
    }
}
EOF
  chown ${APP_USER}:${APP_USER} ${SATIS_FILE}
fi

if [ -n "${SSH_PRIVATE_KEY}" ] && [ ! -f ${APP_USER_HOME}/.ssh/id_rsa ]; then
  echo "${SSH_PRIVATE_KEY}" > ${APP_USER_HOME}/.ssh/id_rsa
  chmod 400 ${APP_USER_HOME}/.ssh/id_rsa
  chown ${APP_USER}:${APP_USER} ${APP_USER_HOME}/.ssh/id_rsa
fi

if [ -n "${GITHUB_OAUTH}" ] && [ ! -f "${APP_USER_HOME}/.composer/auth.json" ]; then
  cat >${APP_USER_HOME}/.composer/auth.json <<EOF
{
    "github-oauth": {
        "github.com": "${GITHUB_OAUTH}"
    }
}
EOF
  chown ${APP_USER}:${APP_USER} ${APP_USER_HOME}/.composer/auth.json
fi

if [ ! -f ${APP_USER_HOME}/.ssh/config ] && [ -f ${APP_USER_HOME}/.ssh/id_rsa ]; then
  : ${STRICT_HOST_KEY_CHECKING:=no}
  cat >${APP_USER_HOME}/.ssh/config <<EOF
Host *
IdentityFile ${APP_USER_HOME}/.ssh/id_rsa
StrictHostKeyChecking ${STRICT_HOST_KEY_CHECKING}
EOF
chmod 400 ${APP_USER_HOME}/.ssh/config
chown ${APP_USER}:${APP_USER} ${APP_USER_HOME}/.ssh/config
fi

if [[ "${CRON_ENABLED}" == "true" ]]; then
  ./sync_repos.sh ${CRON_SYNC_EVERY}&
fi

php-fpm81
nginx
