# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Default box (x86/Intel)
  config.vm.box = "bento/ubuntu-24.04"

  # MacOS Apple Silicon (ARM64) Configuration using QEMU
  if RbConfig::CONFIG['host_cpu'] =~ /arm64|aarch64/
     config.vm.box = "perk/ubuntu-24.04-arm64"
     
     config.vm.provider "qemu" do |qe|
       # Using user provided path, ensure qemu is installed via brew
       qe.qemu_dir = "/opt/homebrew/share/qemu"
       qe.arch = "aarch64"
       qe.machine = "virt"
       
       # Port forwarding manually as qemu provider sometimes needs explicit args
       # ssh_port is handled by vagrant usually, but user specified 50023
       # qe.ssh_port = "50023" 
       
       # Forward Kong ports
       # qe.extra_netdev_args = "hostfwd=tcp::8001-:8001,hostfwd=tcp::8002-:8002,hostfwd=tcp::8443-:8443"
       # Note: Vagrant forwarded_port works with QEMU usually, let's try standard way first to keeps things clean, 
       # or use user args if standard fails.
       # User snippet was explicit about extra_netdev_args, let's inject them if we can't use config.vm.network
     end
  end

  # Configure Port Forwarding (Generic)
  config.vm.network "forwarded_port", guest: 8000, host: 8000 # Proxy
  config.vm.network "forwarded_port", guest: 8001, host: 8001 # Admin API
  config.vm.network "forwarded_port", guest: 8002, host: 8002 # Admin GUI
  config.vm.network "forwarded_port", guest: 8443, host: 8443 # Proxy SSL

  # VM Redis
  config.vm.define "redis" do |redis|
    redis.vm.hostname = "redis" 
    # Private network for inter-vm comms (might need bridge on some providers)
    # Using simple provisioning for now
    redis.vm.provision "shell", inline: <<-SHELL
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y redis-server
      sed -i 's/^bind 127.0.0.1 ::1/bind 0.0.0.0/' /etc/redis/redis.conf
      systemctl restart redis-server
    SHELL
  end

  # VM Kong
  config.vm.define "kong" do |kong|
    kong.vm.hostname = "kong-gateway"
    kong.vm.provision "shell", inline: <<-SHELL
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y curl gnupg2 lsb-release

      # Kong 3.9 installation for Ubuntu Noble (24.04)
      curl -sL https://packages.konghq.com/public/gpg.key | apt-key add -
      echo "deb [arch=$(dpkg --print-architecture)] https://packages.konghq.com/ubuntu noble main" | tee /etc/apt/sources.list.d/kong.list
      
      apt-get update
      # Install specific version 3.9 if available, or latest
      apt-get install -y kong

      # Setup dev environment
      cp /etc/kong/kong.conf.default /etc/kong/kong.conf
      echo "database = off" >> /etc/kong/kong.conf
      echo "declarative_config = /vagrant/kong.yml" >> /etc/kong/kong.conf
      echo "plugins = bundled,oidc" >> /etc/kong/kong.conf
      echo "lua_package_path = /vagrant/?.lua;/vagrant/?/init.lua;;" >> /etc/kong/kong.conf
      
      # Allow admin api from outside
      echo "admin_listen = 0.0.0.0:8001, 0.0.0.0:8444 ssl" >> /etc/kong/kong.conf
      echo "proxy_listen = 0.0.0.0:8000, 0.0.0.0:8443 ssl" >> /etc/kong/kong.conf
      
      systemctl enable kong
      systemctl restart kong
    SHELL
  end
end
