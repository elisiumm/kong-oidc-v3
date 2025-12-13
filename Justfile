default: test

# Install development dependencies
setup:
    luarocks install busted
    luarocks install luacheck

# Run unit tests (spec/unit) using Busted
test:
    busted spec/unit

# Run linter on plugin code
lint:
    luacheck kong/plugins/oidc

# Start the Integration Environment (Kong + Redis)
up:
    vagrant up

# Stop the Integration Environment
down:
    vagrant halt

# Destroy the Integration Environment
destroy:
    vagrant destroy -f

# SSH into the Kong VM
ssh:
    vagrant ssh kong

# SSH into the Redis VM
ssh-redis:
    vagrant ssh redis

# Tail Kong logs
logs:
    vagrant ssh kong -c "tail -f /usr/local/kong/logs/error.log"

# Reload Vagrant provision
reload:
    vagrant reload --provision
