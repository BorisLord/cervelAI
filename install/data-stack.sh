#!/usr/bin/env bash
# install/data-stack.sh: DB clients + data CLIs. CERVELAI_DATA_STACK=<csv|all>.

install_data_stack_sqlite3() { apt_install sqlite3; }
install_data_stack_postgresql_client() { apt_install postgresql-client; }
install_data_stack_redis_tools() { apt_install redis-tools; }
install_data_stack_usql() { mise_aqua "xo/usql"; }
install_data_stack_duckdb() { mise_aqua "duckdb/duckdb"; }
install_data_stack_mlr() { mise_use "aqua:johnkerl/miller" latest mlr; }
install_data_stack_pgcli() { mise_use "pipx:pgcli" latest pgcli; }
install_data_stack_mycli() { mise_use "pipx:mycli" latest mycli; }
install_data_stack_litecli() { mise_use "pipx:litecli" latest litecli; }
install_data_stack_lazysql() { mise_aqua "jorgerojas26/lazysql"; }

install_data_stack_all() {
    _dispatch_csv data-stack CERVELAI_DATA_STACK \
        "sqlite3,postgresql-client,redis-tools,usql,duckdb,mlr,pgcli,mycli,litecli,lazysql"
}
