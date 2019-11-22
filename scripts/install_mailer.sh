#!/usr/bin/env bash

# Mail Installer
# Min. Requirement  : GNU/Linux Ubuntu 14.04
# Last Build        : 12/07/2019
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

# Install Postfix mail server
function install_postfix() {
    if "${AUTO_INSTALL}"; then
        DO_INSTALL_POSTFIX="y"
    else
        while [[ "${DO_INSTALL_POSTFIX}" != "y" && "${DO_INSTALL_POSTFIX}" != "n" ]]; do
            read -rp "Do you want to install Postfix Mail Transfer Agent? [y/n]: " -i y -e DO_INSTALL_POSTFIX
        done
    fi

    if [[ ${DO_INSTALL_POSTFIX} == y* && "${INSTALL_POSTFIX}" == true ]]; then
        echo "Installing Postfix Mail Transfer Agent..."

        run apt-get -qq install -y mailutils postfix

        # Installation status.
        if "${DRYRUN}"; then
            warning "Postfix installed in dryrun mode."
        else
            if [[ $(pgrep -c postfix) -gt 0 ]]; then
                status "Postfix installed successfully."
            else
                warning "Something wrong with Postfix installation."
            fi
        fi
    fi
}

# Install Dovecot
function install_dovecot() {
    if "${AUTO_INSTALL}"; then
        DO_INSTALL_DOVECOT="y"
    else
        while [[ "${DO_INSTALL_DOVECOT}" != "y" && "${DO_INSTALL_DOVECOT}" != "n" ]]; do
            read -rp "Do you want to install Dovecot IMAP and POP3 email server? [y/n]: " -i y -e DO_INSTALL_DOVECOT
        done
    fi

    if [[ ${DO_INSTALL_DOVECOT} == y* && "${INSTALL_DOVECOT}" == true ]]; then
        echo "Installing Dovecot IMAP and POP3 email server..."

        run apt-get -qq install -y dovecot-core dovecot-common dovecot-imapd dovecot-pop3d

        # Installation status.
        if "${DRYRUN}"; then
            warning "Dovecot installed in dryrun mode."
        else
            if [[ $(pgrep -c dovecot) -gt 0 ]]; then
                status "Dovecot installed successfully."
            else
                warning "Something wrong with Dovecot installation."
            fi
        fi
    fi
}

## TODO: Postfix and Dovecot default configuration
# https://www.linode.com/docs/email/postfix/email-with-postfix-dovecot-and-mysql/


echo "[Mail Server Installation]"

# Start running things from a call at the end so if this script is executed
# after a partial download it doesn't do anything.
if [[ -n $(command -v postfix) ]]; then
    warning "Postfix already exists. Installation skipped..."
else
    install_postfix "$@"
fi

if [[ -n $(command -v dovecot) ]]; then
    warning "Dovecot already exists. Installation skipped..."
else
    install_dovecot "$@"
fi
