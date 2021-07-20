#!/bin/bash

set -ev

# Start Echo API
bundle exec rackup --port 3000 --host 0.0.0.0 --env production &

# Sleep
sleep 10

# test Echo API
curl --fail http://0.0.0.0:3000/test
