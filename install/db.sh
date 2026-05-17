#!/usr/bin/env bash
# install/db.sh: DB clients for agents that query real databases. Opt-in.

install_db_all() {
    apt_install sqlite3
    apt_install postgresql-client
    apt_install redis-tools
    mise_aqua "xo/usql"
}
