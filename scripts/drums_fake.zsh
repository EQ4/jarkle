#!/usr/bin/env zsh

setopt ERR_EXIT
setopt NO_UNSET

repo=$(realpath "$(dirname "$(realpath -- $0)")/..")

unsetopt NO_UNSET
source $repo/local/venv/bin/activate
setopt NO_UNSET

exec python $repo/tools/drums_fake.py $@

