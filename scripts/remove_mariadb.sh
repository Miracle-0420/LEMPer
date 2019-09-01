#!/usr/bin/env bash

# MariaDB (MySQL) Uninstaller
# Min. Requirement  : GNU/Linux Ubuntu 14.04
# Last Build        : 31/07/2019
# Author            : ESLabs.ID (eslabs.id@gmail.com)
# Since Version     : 1.0.0

# Include helper functions.
if [ "$(type -t run)" != "function" ]; then
    BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
    # shellchechk source=scripts/helper.sh
    # shellcheck disable=SC1090
    . "${BASEDIR}/helper.sh"
fi

# Make sure only root can run this installer script.
requires_root

function init_mariadb_removal() {
    # Stop MariaDB mysql server process.
    if [[ $(pgrep -c mysqld) -gt 0 ]]; then
        run service mysql stop
    fi

    if dpkg-query -l | awk '/mariadb/ { print $2 }' | grep -qwE "^mariadb-server"; then
        echo "Found MariaDB package installation. Removing..."

        # Remove MariaDB server.
        run apt-get -qq --purge remove -y libmariadbclient18 mariadb-backup mariadb-common mariadb-server

        # Remove repository.
        if "${FORCE_REMOVE}"; then
            run rm -f /etc/apt/sources.list.d/MariaDB-*.list
        fi
    elif dpkg-query -l | awk '/mysql/ { print $2 }' | grep -qwE "^mysql-server"; then
        echo "Found MySQL package installation. Removing..."

        # Remove MySQL server.
        run apt-get -qq --purge remove -y mysql-client mysql-common mysql-server
    else
        echo "Mariadb package not found, possibly installed from source."
        echo "Remove it manually!!"

        MYSQL_BIN=$(command -v mysql)
        MYSQLD_BIN=$(command -v mysqld)

        echo "Mysql binary executable: ${MYSQL_BIN}"
        echo "Mysqld binary executable: ${MYSQLD_BIN}"
    fi

    # Remove MariaDB (MySQL) config files.
    warning "!! This action is not reversible !!"
    while [[ "${REMOVE_MYSQLCONFIG}" != "y" && "${REMOVE_MYSQLCONFIG}" != "n" && "${AUTO_REMOVE}" != true ]]; do
        read -rp "Remove MariaDB (MySQL) database and configuration files? [y/n]: " \
        -i n -e REMOVE_MYSQLCONFIG
    done
    if [[ "${REMOVE_MYSQLCONFIG}" == Y* || "${REMOVE_MYSQLCONFIG}" == y* || "${FORCE_REMOVE}" == true ]]; then
        if [ -d /etc/mysql ]; then
            run rm -fr /etc/mysql
        fi
        
        if [ -d /var/lib/mysql ]; then
            run rm -fr /var/lib/mysql
        fi
        echo "All your SQL database and configuration files deleted permanently."
    fi

    # Final test.
    if "${DRYRUN}"; then
        warning "MariaDB (MySQL) server removed in dryrun mode."
    else
        if [[ -z $(command -v mysqld) ]]; then
            status "MariaDB (MySQL) server removed."
        else
            warning "MariaDB (MySQL) server not removed."
        fi
    fi
}

echo "Uninstalling MariaDB (MySQL) server..."
if [[ -n $(command -v mysql) || -n $(command -v mysqld) ]]; then
    while [[ "${REMOVE_MARIADB}" != "y" && "${REMOVE_MARIADB}" != "n" && "${AUTO_REMOVE}" != true ]]; do
        read -rp "Are you sure to to remove MariaDB (MySQL)? [y/n]: " -e REMOVE_MARIADB
    done
    if [[ "${REMOVE_MARIADB}" == Y* || "${REMOVE_MARIADB}" == y* || "${AUTO_REMOVE}" == true ]]; then
        init_mariadb_removal "$@"
    else
        echo "Found MariaDB (MySQL), but not removed."
    fi
else
    warning "Oops, MariaDB (MySQL) installation not found."
fi
