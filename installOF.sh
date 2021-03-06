#!/bin/bash
#-----------------------------------------------------------------------
#   Nucleation - Nucleation (an unofficial OpenFOAM Installer) lower
#the work to have foam in your system.
#
#   visit: http://code.google.com/p/nucleation/
#
#-----------------------------------------------------------------------
#    This file is part of Nucleation.
#
#    Nucleation is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Nucleation is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Nucleation.  If not, see <http://www.gnu.org/licenses/>.
#-----------------------------------------------------------------------
#
# USAGE:
#   Move this script "installOF.sh" to
#   $ chmod +x installOF.sh
#   $ ./installOF.sh
#
# Several people have contributed for this project on http://www.cfd-online.com
#-----------------------TODOS--------------------------------------
#See the file task.list

#GLOBAL VARIABLES
#Main page URL
MAIN_PAGE_URL="http://code.google.com/p/nucleation"

#Contribs subpage
CONTRIBS_WIKIPAGE_PATH="wiki/Contribs"

#This script's repository
SCRIPT_REPO="http://modular.nucleation.googlecode.com/hg"

#The script's dependencies
SCRIPT_TARBALL="installOF.tar.gz"

#The forum thread for reports and project's page for issues
FORUM_THREAD="http://www.cfd-online.com/Forums/openfoam-installation/73805-openfoam-1-6-x-installer-ubuntu.html"
SCRIPT_ISSUES_URL="https://code.google.com/p/nucleation/issues/list"

#Code ---------------------------------------------------------
#Starting script
echo "-------------------------------------------------------------"
echo "Starting script..."

#make the script abort if something goes wrong
set -e

#run from the script's own directory
cd ${0%/*} || ( echo "You must run this script from its own folder."; exit 1 )

#block attempts to run this script as superuser. If the user wants to install in a system folder,
#let him/her set proper permissions to that folder first!
if [ $(/usr/bin/id -u) -eq 0 ]; then
    echo -e "Please do not run this script with superuser/root powers!!\n"
    echo "If you need to install OpenFOAM in a system folder,"
    echo "please change the permissions to the desired folder"
    echo "for this installation only, and then change back when complete."
    echo "This way we reduce the possible errors this script may incur in"
    echo "your system."
    exit
fi

echo "Detected system specifications:"
#Detect architecture and make an abstract designation
arch=`uname -m`
case $arch in
  i*86)
    arch=x86
    ;;
  x86_64)
    arch=x64
    ;;
  *)
    echo "Sorry, architecture not recognized, aborting."
    exit 1
    ;;
esac

echo "- Architecture: $arch"

#Detect System were the script is running
#start off with the generic installer
INST_SYSTEM=generic
SYSTEM_VERSION=1.0

if [ -e "/etc/lsb-release" ]; then #checking "lsb-release" based distros

  #Check if it's Ubuntu... or any Ubuntu variant with "[Uu]buntu" in the name
  #if [ `grep "DISTRIB_ID=" /etc/lsb-release | sed s/DISTRIB_ID=//g` == "Ubuntu" ]; then
  if grep -i 'Ubuntu' /etc/lsb-release > /dev/null; then
    INST_SYSTEM=ubuntu
    SYSTEM_VERSION=`grep "DISTRIB_RELEASE=" /etc/lsb-release | sed s/DISTRIB_RELEASE=//g`

  #For Debian releases!?
  #elif grep -i 'Debian' /etc/lsb-release > /dev/null; then
  fi

elif [ -e "/etc/SuSE-release" ]; then #checking SuSe based distros
    INST_SYSTEM=suse
    SYSTEM_VERSION=`grep "VERSION =" /etc/SuSE-release | sed s/'VERSION = '//g`
#elif [ -e "/etc/redhat-release" ]; then #checking RedHat based distros
fi

echo "- System: $INST_SYSTEM"
echo "- System version: $SYSTEM_VERSION"

#create work folder
SCRIPT_WORKFOLDER="${PWD}/${0##*/}Files"
if [ ! -d "${SCRIPT_WORKFOLDER}" ]; then
  echo "Creating the work folder ${SCRIPT_WORKFOLDER}"
  mkdir -p ${SCRIPT_WORKFOLDER} || ( echo "Unable to create the work folder ${SCRIPT_WORKFOLDER}. Aborting." ; exit 1 )
fi

#go up to the work folder
cd ${SCRIPT_WORKFOLDER}

#Download the rest of the script's sourcing dependencies and other packages
if [ ! -e "$SCRIPT_TARBALL" ]; then
  echo "Downloading the script's dependencies tarball..."
  wget ${SCRIPT_REPO}/${SCRIPT_TARBALL}
fi
if [ -e "$SCRIPT_TARBALL" ]; then
  echo "Unpacking the script's dependencies tarball..."
  tar -xf ${SCRIPT_TARBALL} || ( echo "Problems unpacking ${SCRIPT_TARBALL}. Aborting." ; exit 1 )
else
  echo "The script's dependencies do not exist, namely ${SCRIPT_TARBALL} wasn't successfully downloaded. Aborting."
  exit 1
fi


#Source all of the common scripts
. ${SCRIPT_WORKFOLDER}/common/aux_functions
. ${SCRIPT_WORKFOLDER}/common/main_functions
. ${SCRIPT_WORKFOLDER}/common/user_interface

#Save stdout and stderr into 4 and 5
SaveSTD_OE_To45

#Set default user options for installation
define_default_user_options

#verify system's language and set to C if not english
if ! issystem_english; then
  set_system_to_neutral_lang
fi

#Script start up complete --------------------------------------------------------
echo "Script start up complete."
echo "-------------------------------------------------------------"
#--------------------------------------------------------


#Now lets interface with the user

#ask the user for what policy to use for running sudo or "su -c"
ask_for_sudo_policy

#make dialog avaliable to use as "GUI", making sudo avaliable if it is installed
install_dialog_package

#INTERACTIVE SECTION  ----------------------------------

#presentation dialog
show_intro_dialog

#Choose path to install OF, default is already set
pick_openfoam_path

#Option for keeping logs of the script's process
should_keep_inst_log

#Collect and generate options list for dialog
collect_list_of_versions

#Choose OpenFOAM version to be installed
pick_openfoam_version

#source version specific scripts
echo "-------------------------------------------------------------"
echo "Sourcing scripts related to the chosen OpenFOAM version..."
. ${SCRIPT_WORKFOLDER}/${OF_MODULE_NAME}/mod.version
. ${SCRIPT_WORKFOLDER}/${OF_MODULE_NAME}/main_functions
. ${SCRIPT_WORKFOLDER}/${OF_MODULE_NAME}/user_interface
. ${SCRIPT_WORKFOLDER}/${OF_MODULE_NAME}/patches
. ${SCRIPT_WORKFOLDER}/${OF_MODULE_NAME}/fixes
echo "Sourcing complete."
echo "-------------------------------------------------------------"

#Define and create base log folders
BASE_LOG_FOLDER="${PATHOF}/buildLogs"
BASE_OFVER_LOG_FOLDER="${BASE_LOG_FOLDER}/${OF_MODULE_NAME}"
BASE_DOWNLOADS_FOLDER="${PATHOF}/Downloads"
mkdir -p "${BASE_LOG_FOLDER}"
mkdir -p "${BASE_OFVER_LOG_FOLDER}"
mkdir -p "${BASE_DOWNLOADS_FOLDER}"

#Installation mode dialog
define_install_mode

#Handle custom options
define_base_custom_options

if [ "x$INSTALLMODE" != "xupdate" ]; then

  #Define options for OpenFOAM optionals
  define_custom_optionals

  #Define options for OpenFOAM optionals
  define_paraview_options

  #Check the sanity of the options
  check_options_sanity

  #GCC compiling settings
  gcc_related_options

  #Mirror selection dialog
  pick_download_mirror

  #Final interface before starting to install
  final_interface_before_install

fi

#Enable this script's logging functionality ...
if [ "x$LOG_OUTPUTS" == "xYes" ]; then
  StartLog
fi

#END OF INTERACTIVE SECTION  ----------------------------------

#have to save a list of the running PIDs, to avoid killing them in the future!
save_running_pids

#Run usual install steps if in "fresh" or "server" install mode
#If not, skip to the last few lines of the script
if [ "x$INSTALLMODE" != "xupdate" ]; then

  #Defining packages to download
  define_packages_to_download

  #Define files (including paths) to the files this script provides
  define_script_s_files

  #install system packages
  install_packages

  #Create OpenFOAM folder in $PATHOF dir
  create_OpenFOAM_folder

  #Download necessary files
  download_files

  #Unpack downloaded files
  unpack_downloaded_files

  #process our timming log, in order to provide progress and estimated timings
  process_online_log_of_timings

  if [ "x$INSTALLMODE" != "xcustom" ]; then

    #git clone OpenFOAM
    OpenFOAM_git_clone

    #apply patches and fixes
    apply_patches_fixes

  fi

  #Activate OpenFOAM environment
  setOpenFOAMEnv

  #Add OpenFOAM's bashrc entry in $PATHOF/.bashrc
  add_openfoam_to_bashrc

  #build gcc
  build_openfoam_gcc

  #This part can't go on without gcc...
  if [ "x$BUILD_GCC_FAILED" != "xYes" ]; then

    if [ "x$INSTALLMODE" != "xcustom" ]; then

      #do an Allwmake on OpenFOAM 1.6.x
      allwmake_openfoam

      #check if the installation is complete
      check_installation

    fi

    #Continue with the next steps, only if it's OK to continue!
    if [ "x$FOAMINSTALLFAILED" == "x" -o "x$FOAMINSTALLFAILED_BUTCONT" == "xYes" ]; then

      #build Doxygen documentation of the code
      allwmake_openfoam_docs

      #build Qt
      build_Qt

      #build CMake
      build_CMake

      #build ParaView
      build_ParaView

      #build the PV3FoamReader plugin
      build_PV3FoamReader

      #build ccm26ToFoam
      build_ccm26ToFoam

    fi
  fi

  #final messages and instructions
  final_messages_for_clean_install

fi

if [ "x$INSTALLMODE" == "xupdate" ]; then

  #Activate OpenFOAM environment
  setOpenFOAMEnv

  #do a git pull
  OpenFOAM_git_pull

  #do an Allwmake on OpenFOAM
  allwmake_openfoam

fi

set +e

if [ "x$FOAMINSTALLFAILED" == "x" -o "x$FOAMINSTALLFAILED_BUTCONT" == "xYes" ]; then
  # NOTE: run bash instead of exit, so the OpenFOAM environment stays operational on
  #the calling terminal.
  cd_openfoam
  #calling bash from here seems to be a bad idea... doesn't seem to work properly...
  #bash
else
  #this shouldn't be necessary, but just in case:
  exit
fi
