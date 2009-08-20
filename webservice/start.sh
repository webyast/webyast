#!/bin/sh -e
rm -f log/development.log
rake db:migrate
ruby script/server --port=8080
