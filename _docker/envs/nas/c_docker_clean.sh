#/bin/bash
docker ps --filter status=dead --filter status=exited -aq  | xargs docker rm -v