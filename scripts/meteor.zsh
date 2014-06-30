#!/usr/bin/env zsh

setopt ERR_EXIT
setopt NO_UNSET

repo=$(realpath "$(dirname "$(realpath -- $0)")/..")

if [[ $# -eq 0 ]]; then
    args=( --settings $repo/local/config/default/meteor_settings.json )
else
    args=( $@ )
fi

cd $repo/src
exec meteor $args

