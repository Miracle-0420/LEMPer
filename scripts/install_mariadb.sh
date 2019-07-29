#!/usr/bin/env bash

# MariaDB (MySQL) Installer
# Min. Requirement  : GNU/Linux Ubuntu 14.04 & 16.04
# Last Build        : 17/07/2019
# Author            : ESLabs.ID (eslabs.id@gmail.com)
# Since Version     : 1.0.0

# Include helper functions.
if [ "$(type -t run)" != "function" ]; then
    BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
    . ${BASEDIR}/helper.sh
fi

# Make sure only root can run this installer script
if [ "$(id -u)" -ne 0 ]; then
    error "You need to be root to run this script"
    exit 1
fi

function init_mariadb_install() {
    echo ""
    echo "Welcome to MariaDB (MySQL) Installation..."
    echo ""

    while [[ $INSTALL_MYSQL != "y" && $INSTALL_MYSQL != "n" ]]; do
        read -p "Do you want to install MariaDB (MySQL) database server? [y/n]: " -e INSTALL_MYSQL
    done

    if [[ "$INSTALL_MYSQL" == Y* || "$INSTALL_MYSQL" == y* ]]; then
        echo -e "\nInstalling MariaDB (MySQL) server..."

        # Install MariaDB
        run apt-get install -y mariadb-server libmariadbclient18

        # Fix MySQL error?
        # Ref: https://serverfault.com/questions/104014/innodb-error-log-file-ib-logfile0-is-of-different-size
        #service mysql stop
        #mv /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile0.bak
        #mv /var/lib/mysql/ib_logfile1 /var/lib/mysql/ib_logfile1.bak
        #service mysql start
        if [[ -n $(which mysql) ]]; then
            if [ ! -f /etc/mysql/my.cnf ]; then
                run cp -f etc/mysql/my.cnf /etc/mysql/
            fi
            if [ ! -f /etc/mysql/mariadb.cnf ]; then
                run cp -f etc/mysql/mariadb.cnf /etc/mysql/
            fi
            if [ ! -f /etc/mysql/debian.cnf ]; then
                run cp -f etc/mysql/debian.cnf /etc/mysql/
            fi
            if [ ! -f /etc/mysql/debian-start ]; then
                run cp -f etc/mysql/debian-start /etc/mysql/
                run chmod +x /etc/mysql/debian-start
            fi

            # Restart MariaDB
            run systemctl restart mariadb.service

            # MySQL Secure Install
            run mysql_secure_installation
        fi

        # Installation status.
        if "${DRYRUN}"; then
            status "MariaDB (MySQL) installed in dryrun mode."
        else
            if [[ $(ps -ef | grep -v grep | grep mysql | wc -l) > 0 ]]; then
                status -e "\nMariaDB (MySQL) installed successfully."
            else
                warning -e "\nSomething wrong with MariaDB (MySQL) installation."
            fi
        fi
    fi
}

# Start running things from a call at the end so if this script is executed
# after a partial download it doesn't do anything.
if [[ -n $(which mysql) ]]; then
    warning -e "\nMariaDB (MySQL) web server already exists. Installation skipped..."
else
    init_mariadb_install "$@"
fi
