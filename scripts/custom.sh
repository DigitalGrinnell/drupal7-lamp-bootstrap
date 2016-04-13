#!/bin/bash

# custom.sh
#
# When placed in the ../scripts directory this bash script is automatically invoked by
# Vagrant (see Vagrantfile for details).  To make the Vagrant and shell provisioning process
# infinitely extendable, this script will scan the ../scripts/custom/ directory for other *.sh
# bash scripts and provision the VM from them.
#
# Changes:
# 26-Mar-2016 - Initial script.
#

echo "Installing customizations per ../scripts/custom.sh."

current_dir=$1
arg2=$2
arg3=$3
arg4=$4

echo "...Arguments are: '${current_dir}' '${arg2}' '${arg3}' '${arg4}'"

# Run all the scripts (*.sh) found in ../scripts/custom/.
for SCRIPT in "${current_dir}/scripts/custom/*.sh"
do
  if [ -f ${SCRIPT} ]
  then
    echo "Custom.sh is invoking script '${SCRIPT}'..."
	source ${SCRIPT} ${current_dir} ${arg2} ${arg3} ${arg4}
  fi
done

