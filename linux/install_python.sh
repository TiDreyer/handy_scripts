#!/usr/bin/env bash
# install the latest python version from source, since Debian/Ubuntu packages are usually outdated
# download links can be found on: https://www.python.org/downloads/source/
# instructions on the build process are given here: https://docs.python.org/3/using/unix.html#building-python

# change these two variables to use a different version
# md5 sums for the XZ-compressed source can be found on the release pages:
# e.g. https://www.python.org/downloads/release/python-3124/

# PYTHON_VERSION=3.8.19  &&  MD5SUM_CHECK=2532d25930266546822c144b99652254
# PYTHON_VERSION=3.9.19  &&  MD5SUM_CHECK=87d0f8281237b972ff8b23e0e2c8d325
# PYTHON_VERSION=3.10.14  &&  MD5SUM_CHECK=05148354ce821ba7369e5b7958435400
# PYTHON_VERSION=3.11.9  &&  MD5SUM_CHECK=22ea467e7d915477152e99d5da856ddc
PYTHON_VERSION=3.12.4  &&  MD5SUM_CHECK=d68f25193eec491eb54bc2ea664a05bd

function check_for_root {
    if [ "$(whoami)" != "root" ]; then
        echo "please run this script as root or via sudo!"
        return 1
    fi
}

function install_dependencies {
    echo "################################################################################"
    echo "#  1. install dependencies                                                     #"
    echo "################################################################################"
    apt-get update
    apt-get build-dep python3
    if apt-get install build-essential gdb lcov pkg-config \
        libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
        libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
        lzma lzma-dev tk-dev uuid-dev zlib1g-dev
    then
        :  # do nothing
    else
        echo "dependencies could not be installed completely"
        return 1
    fi
}

function get_source_code {
    echo "################################################################################"
    echo "#  2. download and extract source code                                         #"
    echo "################################################################################"
    FILE_NAME="Python-${PYTHON_VERSION}.tar.xz"
    wget "https://www.python.org/ftp/python/${PYTHON_VERSION}/${FILE_NAME}"
    MD5SUM_REAL="$(md5sum ${FILE_NAME})"
    if [ "${MD5SUM_REAL}" == "${MD5SUM_CHECK}  ${FILE_NAME}" ]; then
        echo "md5sum is valid"
    else
        echo "md5sum: ${MD5SUM_REAL}"
        echo "invalid md5sum! -- aborting installation"
        return 1
    fi
    tar -xf ${FILE_NAME} && rm ${FILE_NAME}
}

function build_python {
    echo "################################################################################"
    echo "#  3. build and install python from source                                     #"
    echo "################################################################################"
    DIR_NAME="Python-${PYTHON_VERSION}"
    pushd ${DIR_NAME} || return 1
    echo "#####  3.1 configure build options  ############################################"
    ./configure --enable-optimizations --with-lto || return 1
    echo "#####  3.2 build the binary  ###################################################"
    make || return 1
    echo "#####  3.3 install on the system  ##############################################"
    make altinstall || return 1
    popd || return 1
    rm -r ${DIR_NAME}
}

function make_default {
    echo "################################################################################"
    echo "#  4. link new python version as default                                       #"
    echo "################################################################################"
    IFS='.' read -ra VERSION_ARRAY <<< "$PYTHON_VERSION"
    BINARY_NAME_MAJOR_VERSION="python${VERSION_ARRAY[0]}"
    BINARY_NAME_MINOR_VERSION="python${VERSION_ARRAY[0]}.${VERSION_ARRAY[1]}"
    INSTALLED_BINARY_PATH=$(which "${BINARY_NAME_MINOR_VERSION}")
    ln -fs "${INSTALLED_BINARY_PATH}" "/usr/bin/${BINARY_NAME_MAJOR_VERSION}"
    ln -fs "/usr/bin/${BINARY_NAME_MAJOR_VERSION}" "/usr/bin/python"
    ls -l /usr/bin/python*
}

function main {
    check_for_root || return 1
    install_dependencies || return 2
    get_source_code || return 3
    build_python || return 4
    # uncomment, if you want the new version to become the default:
    # make_default || exreturnit 5
}

time main
