#!/bin/bash
#
#
# USAGE: 
#   Move this script "installOF.sh" to
#   $ chmod +x installOF.sh
#   $ ./installOF.sh
#
# THIS SCRIPT IS UNDER GPLv3 LICENSE
# See script home at:
# http://code.google.com/p/openfoam-ubuntu
#
# Several people have contributed for this project on http://www.cfd-online.com
#-----------------------TODOS--------------------------------------
#See the file task.list

#GLOBAL VARIABLES
#Main page URL
MAIN_PAGE_URL="http://code.google.com/p/openfoam-ubuntu"
#This script's repository
SCRIPT_REPO="http://modular.openfoam-ubuntu.googlecode.com/hg/"
#The script's dependencies
SCRIPT_TARBALL="installOF.tar.gz"

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

if [ -e "/etc/lsb-release" ]; then
  #Check if it's Ubuntu
  if [ `cat /etc/lsb-release | grep DISTRIB_ID= | sed s/DISTRIB_ID=//g` == "Ubuntu" ]; then
    INST_SYSTEM=ubuntu
    SYSTEM_VERSION=`cat /etc/lsb-release | grep DISTRIB_RELEASE= | sed s/DISTRIB_RELEASE=//g`
  fi
fi

echo "- System: $INST_SYSTEM"
echo "- System version: $SYSTEM_VERSION"

#create work folder
SCRIPT_WORKFOLDER="${0%/*}/${0##*/}Files"
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

#Choose OpenFOAM version to be installed
pick_openfoam_version

#source version specific scripts
. ${SCRIPT_WORKFOLDER}/of${OF_SHORT_VERSION}/main_functions
. ${SCRIPT_WORKFOLDER}/of${OF_SHORT_VERSION}/user_interface
. ${SCRIPT_WORKFOLDER}/of${OF_SHORT_VERSION}/patches

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
if [ "$LOG_OUTPUTS" == "Yes" ]; then
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

  #fix the tutorials (works only after setting the environment)
  fix_tutorials

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
