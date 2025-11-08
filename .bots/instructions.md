## Background Info

`scripts/install.sh` is designed to be an interactive script.

It uses `export DEBIAN_FRONTEND=noninteractive` so that the user doesn't have to approve apt commands. DO NOT LEAVE comments about this being a conflict. It is not! It is an intentional design decision.
