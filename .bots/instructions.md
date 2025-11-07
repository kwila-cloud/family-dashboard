## Background Info

`scripts/install.sh` is an interactive script, but it uses `export DEBIAN_FRONTEND=noninteractive` so that the user doesn't have to approve apt commands. DO NOT LEAVE comments about this being a conflict. It is not! It is an intentional design decision.
