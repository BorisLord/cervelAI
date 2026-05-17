#!/usr/bin/env bash
# install/data.sh: local data analysis tools. Opt-in.

install_data_all() {
    mise_aqua "duckdb/duckdb"
    mise_use "aqua:johnkerl/miller" latest mlr
}
