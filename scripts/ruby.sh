#!/usr/bin/env bash
#set -e

function setup() 
{
  pwd
  cd conf-logstash/ruby
  sudo gem install bundler
  bundle install
}

# Entry point
function main() {
  setup 
  echo "pwd in after setup is: $(pwd)"
  bundle exec rspec
}

main
