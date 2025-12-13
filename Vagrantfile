# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Default box (x86/Intel)
  config.vm.box = "bento/ubuntu-24.04"

  # MacOS Apple Silicon (ARM64) Configuration using QEMU
  if RbConfig::CONFIG['host_cpu'] =~ /arm64|aarch64/
     config.vm.box = "perk/ubuntu-24.04-arm64"
     
     config.vm.provider "qemu" do |qe|
       # Global QEMU settings
       qe.qemu_dir = "/opt/homebrew/share/qemu"
       qe.arch = "aarch64"
       qe.machine = "virt,highmem=on,accel=hvf"
       qe.memory = "2048"
     end
  end

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

    redis.vm.provider "qemu" do |qe|
       qe.ssh_port = "50030"
       qe.extra_netdev_args = "hostfwd=tcp::6379-:6379"
    end
  end

  # VM Kong
  config.vm.define "kong" do |kong|
    kong.vm.hostname = "kong-gateway"
    kong.vm.provider "qemu" do |qe|
       qe.ssh_port = "50031"
       qe.extra_netdev_args = "hostfwd=tcp::8000-:8000,hostfwd=tcp::8001-:8001,hostfwd=tcp::8002-:8002,hostfwd=tcp::8443-:8443"
    end
    kong.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y curl gnupg2 lsb-release

      # Kong 3.9 installation for Ubuntu Noble (24.04)
      curl -1sLf "https://packages.konghq.com/public/gateway-39/gpg.B9DCD032B1696A89.key" | gpg --dearmor | tee /usr/share/keyrings/kong-gateway-39-archive-keyring.gpg > /dev/null
      curl -1sLf "https://packages.konghq.com/public/gateway-39/config.deb.txt?distro=ubuntu&codename=noble" | tee /etc/apt/sources.list.d/kong-gateway-39.list > /dev/null
      
      apt-get update
      apt-get install -y kong/noble
      apt-get install -y zip
      apt-get install -y postgresql postgresql-contrib
      systemctl enable postgresql

      echo "database = postgres" >> /etc/kong/kong.conf
      echo "pg_host = 127.0.0.1" >> /etc/kong/kong.conf
      echo "pg_port = 5432" >> /etc/kong/kong.conf
      echo "pg_user = kong" >> /etc/kong/kong.conf
      echo "pg_password = super_secret" >> /etc/kong/kong.conf
      echo "pg_database = kong" >> /etc/kong/kong.conf
      echo "admin_listen = 0.0.0.0:8001" >> /etc/kong/kong.conf
      echo "admin_gui_listen = 0.0.0.0:8002" >> /etc/kong/kong.conf
      echo "admin_gui_url = http://localhost:8002" >> /etc/kong/kong.conf
      echo "plugins = bundled,oidc" >> /etc/kong/kong.conf
      echo "nginx_proxy_include = /etc/kong/nginx_oidc_variables.conf" >> /etc/kong/kong.conf
      echo "nginx_http_lua_shared_dict = discovery 30m" >> /etc/kong/kong.conf

      SESSION_SECRET="$(openssl rand -base64 32)"
      printf "set \\$session_secret '%s';\n" "$SESSION_SECRET" | sudo tee /etc/kong/nginx_oidc_variables.conf >/dev/null

      sudo -i -u postgres psql -c "CREATE USER kong WITH PASSWORD 'super_secret';"
      sudo -i -u postgres psql -c "CREATE DATABASE kong OWNER kong;"

      sudo luarocks install kong-openidconnect-code-flow-v3
      sudo -E kong migrations bootstrap -c /etc/kong/kong.conf
      sudo -E kong start -c /etc/kong/kong.conf

    SHELL
  end
end
