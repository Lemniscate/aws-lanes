#!/bin/bash
rm awslanes-* 
bundle install --path .bundle/gems --binstubs .bundle/bin \
  && gem build awslanes.gemspec \
  && gem install awslanes-*.gem \
  && lanes

