#!/usr/bin/env bash
# Based on: https://github.com/NTBBloodbath/nvim/blob/e0ad6fcd5aae6e9b1599e44953a48a31f865becc/extern/measure_nvim.sh

get_time() {
    grep "NVIM STARTED" <tmp | cut -d ' ' -f 1
}

pf() {
    printf '%s : ' "$@"
}

# for idx in {1..5}
# do
#     echo "Warmup #$idx"
#     # nvim -c q >/dev/null
#     nvim -c q 2>&1 | tee -a /dev/null
# done

pf "No config"
nvim --startuptime tmp --clean -nu NORC
get_time
rm tmp

pf "With config"
nvim --startuptime tmp
get_time
rm tmp

pf "Opening init.lua"
nvim --startuptime tmp "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua"
get_time
rm tmp

pf "Opening Python file"
nvim --startuptime tmp ~/Developer/kyleking/corallium/corallium/pretty_process.py
get_time
rm tmp
