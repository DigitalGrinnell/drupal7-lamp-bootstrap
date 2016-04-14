#!/bin/bash

echo "This is custom.sh"
echo "-----------------------------------------------------------------"

# custom.sh
#
# When placed in the ../scripts directory this bash script is automatically invoked by
# Vagrant (see Vagrantfile for details).  To make the Vagrant and shell provisioning process
# infinitely extendable, this script will scan the ../scripts/custom/ directory for other *.sh
# bash scripts and provision the VM from them.
#
# Changes:
# 14-Apr-2016 - Passing argument $share and reading variables from $share/config.yaml
# 26-Mar-2016 - Initial script.
#

# Read configuration variables using technique documented at https://gist.github.com/pkuczynski/8665367
share=$1
cd $share
# cd /tmp/drupal7-lamp-bootstrap
# include parse_yaml function
. parse_yaml.sh
# read yaml file
eval $(parse_yaml config.yaml)

# Run all the scripts (*.sh) found in ../scripts/custom/.
for SCRIPT in "${share}/scripts/custom/*.sh"
do
  if [ -f ${SCRIPT} ]
  then
    echo "custom.sh is invoking script '${SCRIPT}'..."
	source ${SCRIPT} ${share}
  fi
done

