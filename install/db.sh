#!/usr/bin/env bash
# install/db.sh — DB clients for agents that query real databases. Opt-in.

install_db_sqlite()   { apt_install sqlite3; }
install_db_psql()     { apt_install postgresql-client; }
install_db_redis()    { apt_install redis-tools; }
install_db_usql()     { mise_aqua "xo/usql"; }

install_db_all() {
    install_db_sqlite
    install_db_psql
    install_db_redis
    install_db_usql
}
