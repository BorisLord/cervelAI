#!/usr/bin/env bash
# install/data-stack.sh: DB clients + data analysis. Opt-in.

install_data_stack_all() {
    apt_install sqlite3
    apt_install postgresql-client
    apt_install redis-tools
    mise_aqua "xo/usql"
    mise_aqua "duckdb/duckdb"
    mise_use "aqua:johnkerl/miller" latest mlr
}
