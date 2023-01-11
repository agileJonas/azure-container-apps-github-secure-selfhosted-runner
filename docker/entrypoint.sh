#!/usr/bin/env bash
set -eEuo pipefail


while getopts t: flag
do
    case "${flag}" in
        p) PAT=${OPTARG};;
        n) NAMERUNNER=${OPTARG};;
        o) ORG=${OPTARG};;
        r) REPO=${OPTARG};;
    esac
done

#PAT=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
#NAMERUNNER=containerapprunner
#ORG=agileJonas
#REPO=azure-container-apps-github-secure-selfhosted-runner

echo "Incoming PAT: ********";
echo "Name of runner group: $NAMERUNNER";
echo "Org: $ORG";
echo "Repo: $REPO";


token_url="https://api.github.com/repos/${ORG}/${REPO}/actions/runners/registration-token"
github_url="https://github.com/${ORG}/${REPO}"

TOKEN=$(curl -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $PAT"  -H "X-GitHub-Api-Version: 2022-11-28" $token_url | jq -r '.token')
DATE=$(date +"%y%m%d_%H%M%S")
FULLRUNNERNAME="${NAMERUNNER}_${DATE}"


# SIGUSR1-handler
my_handler() {
  echo "my_handler called"
}

# SIGTERM-handler
term_handler() {
  echo "term_handler called"
  ./config.sh remove -token "${TOKEN}"
}

echo "Setting up handlers to trap signals";

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; my_handler' SIGUSR1
trap 'kill ${!}; term_handler' SIGTERM


cleanup() {
  ./config.sh remove -token "${TOKEN}"
}

echo "Run config.sh with token: $TOKEN";
./config.sh --url $github_url --token $TOKEN --unattended --replace --name $FULLRUNNERNAME 

./run.sh

echo "Run cleanup";
cleanup