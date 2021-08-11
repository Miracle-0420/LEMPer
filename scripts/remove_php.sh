#!/usr/bin/env bash

# PHP & FPM Uninstaller
# Min. Requirement  : GNU/Linux Ubuntu 16.04
# Last Build        : 12/07/2019
# Author            : MasEDI.Net (me@masedi.net)
# Since Version     : 1.0.0

# Include helper functions.
if [ "$(type -t run)" != "function" ]; then
    BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
    # shellcheck disable=SC1091
    . "${BASEDIR}/helper.sh"
fi

# Make sure only root can run this installer script.
requires_root

function remove_php_fpm() {
    # PHP version.
    local PHPv="${1}"
    if [ -z "${PHPv}" ]; then
        PHPv=${PHP_VERSION:-"7.3"}
    fi

    # Stop default PHP FPM process.
    if [[ $(pgrep -c "php-fpm${PHPv}") -gt 0 ]]; then
        run systemctl stop "php${PHPv}-fpm"
    fi

    if dpkg-query -l | awk '/php/ { print $2 }' | grep -qwE "^php${PHPv}"; then
        echo "Removing PHP ${PHPv} packages installation..."

        # Remove geoip module.
        if "php${PHPv}" -m | grep -qw geoip; then
            # Uninstall geoip pecl.
            #run pecl uninstall geoip-1.1.1

            # Unlink enabled module.
            [ -f "/etc/php/${PHPv}/cli/conf.d/20-geoip.ini" ] && \
            run unlink "/etc/php/${PHPv}/cli/conf.d/20-geoip.ini"

            [ -f "/etc/php/${PHPv}/fpm/conf.d/20-geoip.ini" ] && \
            run unlink "/etc/php/${PHPv}/fpm/conf.d/20-geoip.ini"

            # Remove module.
            run rm -f "/etc/php/${PHPv}/mods-available/geoip.ini"
        fi

        # Remove mcrypt module.
        if [[ "${PHPv//.}" -lt "72" ]]; then
            if "php${PHPv}" -m | grep -qw mcrypt; then
                run apt-get --purge remove -y "php${PHPv}-mcrypt"
            fi
        elif [[ "${PHPv}" == "7.2" ]]; then
            if "php${PHPv}" -m | grep -qw mcrypt; then
                # Uninstall mcrypt pecl.
                #run pecl uninstall mcrypt-1.0.1

                # Unlink enabled module.
                [ -f "/etc/php/${PHPv}/cli/conf.d/20-mcrypt.ini" ] && \
                run unlink "/etc/php/${PHPv}/cli/conf.d/20-mcrypt.ini"

                [ -f "/etc/php/${PHPv}/fpm/conf.d/20-mcrypt.ini" ] && \
                run unlink "/etc/php/${PHPv}/fpm/conf.d/20-mcrypt.ini"

                # Remove module.
                run rm -f "/etc/php/${PHPv}/mods-available/mcrypt.ini"
            fi
        else
            # Use libsodium? remove separately.
            info "If you're installing Libsodium extension, then remove it separately."
        fi

        # Remove PHP packages.
        # shellcheck disable=SC2046
        run apt-get remove --purge -qq -y $(dpkg-query -l | awk '/php/ { print $2 }' | grep -wE "^php${PHPv}")

        # Remove PHP & FPM config files.
        warning "!! This action is not reversible !!"

        if "${AUTO_REMOVE}"; then
            REMOVE_PHPCONFIG="y"
        else
            while [[ "${REMOVE_PHPCONFIG}" != "y" && "${REMOVE_PHPCONFIG}" != "n" ]]; do
                read -rp "Remove PHP ${PHPv} & FPM configuration files? [y/n]: " -e REMOVE_PHPCONFIG
            done
        fi

        if [[ ${REMOVE_PHPCONFIG} == Y* || ${REMOVE_PHPCONFIG} == y* || ${FORCE_REMOVE} == true ]]; then
            [ -d "/etc/php/${PHPv}" ] && run rm -fr "/etc/php/${PHPv}"

            echo "All your configuration files deleted permanently."
        fi

        if [[ -z $(command -v "php${PHPv}") ]]; then
            success "PHP ${PHPv} & FPM installation removed."
        else
            info "Unable to remove PHP ${PHPv} & FPM installation."
        fi
    else
        info "PHP ${PHPv} & FPM installation not found."
    fi   
}

# Remove PHP & FPM.
function init_php_fpm_removal() {
    local SELECTED_PHP=""
    local OPT_PHP_VERSION=""

    OPTS=$(getopt -o p:ir \
        -l php-version: \
        -n "init_php_fpm_install" -- "$@")

    eval set -- "${OPTS}"

    while true
    do
        case "${1}" in
            -p|--php-version) shift
                #SELECTED_PHP="${1}"
                OPT_PHP_VERSION="${1}"
                shift
            ;;
            --) shift
                break
            ;;
            *)
                fail "Invalid argument: ${1}"
                exit 1
            ;;
        esac
    done

    if [ -n "${OPT_PHP_VERSION}" ]; then
        PHP_VERSION=${OPT_PHP_VERSION}
    else
        PHP_VERSION=${PHP_VERSION:-"7.4"}
    fi

    if "${AUTO_REMOVE}"; then
        if [ -z "${SELECTED_PHP}" ]; then
            SELECTED_PHP=${PHP_VERSION}
        fi
    else
        echo "Which version of PHP to be removed?"
        echo "Supported PHP versions:"
        echo "  1). PHP 5.6 (EOL)"
        echo "  2). PHP 7.0 (EOL)"
        echo "  3). PHP 7.1 (EOL)"
        echo "  4). PHP 7.2 (EOL)"
        echo "  5). PHP 7.3 (SFO)"
        echo "  6). PHP 7.4 (Stable)"
        echo "  7). PHP 8.0 (Latest Stable)"
        echo "  8). All available versions"
        echo "--------------------------------------------"
        [ -n "${PHP_VERSION}" ] && \
        info "Pre-defined selected version is: ${PHP_VERSION}"

        while [[ ${SELECTED_PHP} != "1" && ${SELECTED_PHP} != "2" && ${SELECTED_PHP} != "3" && \
                ${SELECTED_PHP} != "4" && ${SELECTED_PHP} != "5" && ${SELECTED_PHP} != "6" && \
                ${SELECTED_PHP} != "7" && ${SELECTED_PHP} != "8" && \
                ${SELECTED_PHP} != "5.6" && ${SELECTED_PHP} != "7.0" && ${SELECTED_PHP} != "7.1" && \
                ${SELECTED_PHP} != "7.2" && ${SELECTED_PHP} != "7.3" && ${SELECTED_PHP} != "7.4" && \
                ${SELECTED_PHP} != "8.0" && ${SELECTED_PHP} != "all" ]]; do
            read -rp "Enter a PHP version from an option above [1-8]: " -i "${PHP_VERSION}" -e SELECTED_PHP
        done
    fi

    #local PHPv
    case ${SELECTED_PHP} in
        1|"5.6")
            #PHPv="5.6"
            remove_php_fpm "5.6"
        ;;
        2|"7.0")
            #PHPv="7.0"
            remove_php_fpm "7.0"
        ;;
        3|"7.1")
            #PHPv="7.1"
            remove_php_fpm "7.1"
        ;;
        4|"7.2")
            #PHPv="7.2"
            remove_php_fpm "7.2"
        ;;
        5|"7.3")
            #PHPv="7.3"
            remove_php_fpm "7.3"
        ;;
        6|"7.4")
            #PHPv="7.4"
            remove_php_fpm "7.4"
        ;;
        7|"8.0")
            #PHPv="8.0"
            remove_php_fpm "8.0"
        ;;
        8|"all")
            # Install all PHP version (except EOL & Beta).
            #PHPv="all"
            #remove_php_fpm "5.6"
            #remove_php_fpm "7.0"
            #remove_php_fpm "7.1"
            #remove_php_fpm "7.2"
            #remove_php_fpm "7.3"
            #remove_php_fpm "7.4"
            #remove_php_fpm "8.0"

            Versions="5.6 7.0 7.1 7.2 7.3 8.0"
            for PHPver in ${Versions}; do
                remove_php_fpm "${PHPver}"
            done
        ;;
        *)
            #PHPv="unsupported"
            error "Your selected PHP version ${SELECTED_PHP} is not supported yet."
        ;;
    esac

    # Also remove default LEMPer PHP.
    DEFAULT_PHP_VERSION=${DEFAULT_PHP_VERSION:-"7.4"}
    remove_php_fpm "${DEFAULT_PHP_VERSION}"

    # Final clean up (executed only if no PHP version installed).
    if "${DRYRUN}"; then
        info "PHP ${SELECTED_PHP} & FPM removed in dryrun mode."
    else
        # New logic for multiple PHP removal in batch.
        PHP_IS_EXISTS=false
        for PHPv in ${SELECTED_PHP}; do
            [[ -n $(command -v "${PHPv}") ]] && PHP_IS_EXISTS=true
        done

        if [[ "${PHP_IS_EXISTS}" == false ]]; then
            echo "Removing additional unused PHP packages..."
            run apt-get remove --purge -qq -y php-common php-pear php-xml pkg-php-tools spawn-fcgi fcgiwrap

            # Remove PHP repository.
            run add-apt-repository -y --remove ppa:ondrej/php

            # Remove all the rest of PHP lib files.
            [ -d /usr/lib/php ] && run rm -fr /usr/lib/php
            [ -d /usr/share/php ] && run rm -fr /usr/share/php
            [ -d /var/lib/php ] && run rm -fr /var/lib/php

            success "All PHP packages installation completely removed."
        fi
    fi
}

echo "Uninstalling PHP & FPM..."
if [[ -n $(command -v php5.6) || \
    -n $(command -v php7.0) || \
    -n $(command -v php7.1) || \
    -n $(command -v php7.2) || \
    -n $(command -v php7.3) || \
    -n $(command -v php7.4) || \
    -n $(command -v php8.0) ]]; then

    if "${AUTO_REMOVE}"; then
        REMOVE_PHP="y"
    else
        while [[ "${REMOVE_PHP}" != "y" && "${REMOVE_PHP}" != "n" ]]; do
            read -rp "Are you sure to remove PHP & FPM? [y/n]: " -e REMOVE_PHP
        done
    fi

    if [[ "${REMOVE_PHP}" == Y* || "${REMOVE_PHP}" == y* ]]; then
        init_php_fpm_removal "$@"
    else
        echo "Found PHP & FPM, but not removed."
    fi
else
    info "Oops, PHP & FPM installation not found."
fi
