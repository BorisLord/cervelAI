#!/usr/bin/env bash
# install/data.sh — local data analysis tools. Opt-in.

install_data_duckdb() { mise_aqua "duckdb/duckdb"; }
install_data_miller() { mise_use "aqua:johnkerl/miller" latest mlr; }

install_data_all() {
    install_data_duckdb
    install_data_miller
}
