#!/bin/busybox sh

################################
#  StelaLinux - stela command  #
#------------------------------#
# Created by AwlsomeAlex GPLv3 #
################################
# Copyright (c) 2020 Alexander Barris <awlsomealex at outlook dot com>
# All Rights Reserved
# ISC License

#----------------------------------#
# ----- Build-Time Variables ----- #
#----------------------------------#

BUILD_NAME=NULL
BUILD_NUMBER=NULL
BUILD_TIME=NULL



#-----------------------#
# ----- Functions ----- #
#-----------------------#

# getBuildName(): Prints the Build Name of StelaLinux
function loka_getBuildName() {
    echo "$BUILD_NAME"
}

# getBuildNumber(): Prints the Build Number of StelaLinux
function loka_getBuildNumber() {
    echo "$BUILD_NUMBER"
}



#----------------------------#
# ----- Main Execution ----- #
#----------------------------#
EXECUTE=$0
ARGUMENT=$1

case "$ARGUMENT" in
    -b )
        loka_getBuildName
        ;;
    -B )
        loka_getBuildNumber
        ;;
    * )
        echo "stela: Invalid Command."
        ;;
esac
