#!/bin/bash

unknown_os ()
{
  echo "Unfortunately, your operating system distribution and version are not supported by this script."
  echo
  echo "You can override the OS detection by setting os= and dist= prior to running this script."
  echo "You can find a list of supported OSes and distributions on our website: https://packagecloud.io/docs#os_distro_version"
  echo
  echo "For example, to force Ubuntu Trusty: os=ubuntu dist=trusty ./script.sh"
  echo
  echo "Please email support@packagecloud.io and let us know if you run into any issues."
  exit 1
}

gpg_check ()
{
  echo "Checking for gpg..."
  if command -v gpg > /dev/null; then
    echo "Detected gpg..."
  else
    echo "Installing gnupg for GPG verification..."
    apt-get install -y gnupg
    if [ "$?" -ne "0" ]; then
      echo "Unable to install GPG! Your base system has a problem; please check your default OS's package repositories because GPG should work."
      echo "Repository installation aborted."
      exit 1
    fi
  fi
}

curl_check ()
{
  echo "Checking for curl..."
  if command -v curl > /dev/null; then
    echo "Detected curl..."
  else
    echo "Installing curl..."
    apt-get install -q -y curl
    if [ "$?" -ne "0" ]; then
      echo "Unable to install curl! Your base system has a problem; please check your default OS's package repositories because curl should work."
      echo "Repository installation aborted."
      exit 1
    fi
  fi
}

install_debian_keyring ()
{
  if [ "${os}" = "debian" ]; then
    echo "Installing debian-archive-keyring which is needed for installing "
    echo "apt-transport-https on many Debian systems."
    apt-get install -y debian-archive-keyring &> /dev/null
  fi
}


detect_os ()
{
  if [[ ( -z "${os}" ) && ( -z "${dist}" ) ]]; then
    # some systems dont have lsb-release yet have the lsb_release binary and
    # vice-versa
    if [ -e /etc/lsb-release ]; then
      . /etc/lsb-release

      if [ "${ID}" = "raspbian" ]; then
        os=${ID}
        dist=`cut --delimiter='.' -f1 /etc/debian_version`
      else
        os=${DISTRIB_ID}
        dist=${DISTRIB_CODENAME}

        if [ -z "$dist" ]; then
          dist=${DISTRIB_RELEASE}
        fi
      fi

    elif [ `which lsb_release 2>/dev/null` ]; then
      dist=`lsb_release -c | cut -f2`
      os=`lsb_release -i | cut -f2 | awk '{ print tolower($1) }'`

    elif [ -e /etc/debian_version ]; then
      # some Debians have jessie/sid in their /etc/debian_version
      # while others have '6.0.7'
      os=`cat /etc/issue | head -1 | awk '{ print tolower($1) }'`
      if grep -q '/' /etc/debian_version; then
        dist=`cut --delimiter='/' -f1 /etc/debian_version`
      else
        dist=`cut --delimiter='.' -f1 /etc/debian_version`
      fi

    else
      unknown_os
    fi
  fi

  if [ -z "$dist" ]; then
    unknown_os
  fi

  # remove whitespace from OS and dist name
  os="${os// /}"
  dist="${dist// /}"

  echo "Detected operating system as $os/$dist."
}

main ()
{
  detect_os
  curl_check
  gpg_check

  # Need to first run apt-get update so that apt-transport-https can be
  # installed
  echo -n "Running apt-get update... "
  apt-get update
  echo "done."

  # Install the debian-archive-keyring package on debian systems so that
  # apt-transport-https can be installed next
  install_debian_keyring

  echo -n "Installing apt-transport-https... "
  apt-get install -y apt-transport-https &> /dev/null
  echo "done."


  gpg_key_url="https://packagecloud.io/fdio/master/gpgkey"
#  apt_config_url="https://packagecloud.io/install/repositories/fdio/master/config_file.list?os=${os}&dist=${dist}&source=script"
  apt_config_url="deb https://packagecloud.io/fdio/vsap/master/ubuntu/ bionic main"
  apt_config_src_url="deb-src https://packagecloud.io/fdio/vsap/master/ubuntu/ bionic main"
  apt_source_path="/etc/apt/sources.list.d/fdio_master.list"

  echo -n "Installing $apt_source_path..."

  # create an apt config file for this repository
  #curl -sSf "${apt_config_url}" > $apt_source_path
  grep -rn "${apt_config_url}" $apt_source_path
  if [ $? -eq 1 ]; then
    echo ${apt_config_url} >> $apt_source_path
    echo ${apt_config_src_url} >> $apt_source_path
  fi

  echo "done."

  echo -n "Importing packagecloud gpg key... "
  # import the gpg key
  curl -L "${gpg_key_url}" 2> /dev/null | apt-key add - &>/dev/null
  echo "done."

  echo -n "Running apt-get update... "
  # update apt on this system
  apt-get update &> /dev/null
  echo "done."

  echo
  echo "The repository is setup! You can now install packages."
}

main

