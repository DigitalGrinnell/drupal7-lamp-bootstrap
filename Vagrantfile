# -*- mode: ruby -*-
# vi: set ft=ruby :

# The following technique borrowed from http://stackoverflow.com/questions/16708917/how-do-i-include-variables-in-my-vagrantfile
require 'yaml'
current_dir = File.dirname(File.expand_path(__FILE__))
configs     = YAML.load_file("#{current_dir}/config.yaml")
vc          = configs['config']

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  $cpus   = ENV.fetch("DRUPAL7_VAGRANT_CPUS", "2")
  $memory = ENV.fetch("DRUPAL7_VAGRANT_MEMORY", "3000")
  $share  = ENV.fetch("DRUPAL7_VAGRANT_SHARE", "/var/drupal7-lamp-bootstrap")

  # Configure vagrant hostupdater to work
  # Create a private network, which allows host-only access to the machine using a specific IP.
  config.vm.hostname = vc['hostname']
  config.vm.network :private_network, ip: vc['private_ip']
  config.hostsupdater.aliases = [ vc['aliases'] ]

  config.vm.provider "virtualbox" do |v|
    v.name = "Drupal 7 Development VM"
  end

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/trusty64"

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", $memory]
    vb.customize ["modifyvm", :id, "--cpus", $cpus]
  end

  # Share an additional folder to the guest VM. The first argument is the path on the host to the actual folder.
  # The second argument is the path on the guest to mount the folder.
  config.vm.synced_folder "./", $share


  # Define the bootstrap file: A (shell) script that runs after first setup of your box (= provisioning)
  config.vm.provision :shell, path: "bootstrap.sh", :privileged => true, :args => $share

  # If there is a ./scripts/custom.sh defined...run it now
  if File.exist?("./scripts/custom.sh") then
    config.vm.provision :shell, path: "./scripts/custom.sh", :privileged => true, :args => $share
  end

end
