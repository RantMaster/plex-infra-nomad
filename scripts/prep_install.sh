#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/variables.sh

echo -e "\n\n### Preparing your system ###\n\n"

# Add the plex user and group with specified UID before doing anything
echo "Adding ${PLEX_USER} with UID:${PLEX_UID}"
sudo adduser ${PLEX_USER} --uid=${PLEX_UID} -U

# Install packages needed
echo "Installing packages: ${PACKAGES}"
sudo yum -y install ${PACKAGES}

# Enable cockpit
echo "Enabling cockpiti for remote web administration. Access via https://<ip>:9090"
sudo systemctl enable --now cockpit.socket

# Set default zone to trusted assuming you're on a private net behind a firewall
echo "Setting FirewallD to live in a trusted zone. Comment this out if you're in a DMZ"
sudo firewall-cmd --set-default-zone=trusted

# Disable SELinux because reasons. Sorry Dan
echo "Disabling SELinux. This will require a reboot to take effect"
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux

# Create download directories
for MEDIATYPE in "${DOWNLOADABLES[@]}"; do

  MEDIADIR=${COMPLETED_DIR}/${MEDIATYPE}

  echo "Creating ${MEDIADIR}"
  sudo mkdir -p ${MEDIADIR}

  echo "Changing permissions on ${MEDIADIR} to ${PLEX_USER}.${PLEX_GROUP}"
  sudo chown -R ${PLEX_USER}.${PLEX_GROUP} ${MEDIADIR}

done

echo "Creating ${TRANSCODE_DIR}"
sudo mkdir -p ${TRANSCODE_DIR}

echo "Changing permissions on ${TRANSCODE_DIR} to ${PLEX_USER}.${PLEX_GROUP}"
sudo chown -R ${PLEX_USER}.${PLEX_GROUP} ${TRANSCODE_DIR}

echo "Done preparing your system. Ready for services installation"
