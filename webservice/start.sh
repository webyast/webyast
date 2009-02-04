#!/bin/sh
rm -f log/development.log
ruby script/server --port=8080
