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
    local csv="${CERVELAI_DATA_STACK:-}"
    [[ "$csv" == "all" ]] && csv="sqlite3,postgresql-client,redis-tools,usql,duckdb,mlr,pgcli,mycli,litecli,lazysql"
    IFS=',' read -r -a list <<<"$csv"
    for d in "${list[@]}"; do
        d="${d// /}"
        case "$d" in
            sqlite3 | postgresql-client | redis-tools | usql | duckdb | mlr | pgcli | mycli | litecli | lazysql)
                "install_data_stack_${d//-/_}"
                ;;
            none | "") log_skip "no data-stack tool requested" ;;
            *) log_warn "unknown data-stack in CERVELAI_DATA_STACK: $d (valid: sqlite3,postgresql-client,redis-tools,usql,duckdb,mlr,pgcli,mycli,litecli,lazysql,none)" ;;
        esac
    done
}
