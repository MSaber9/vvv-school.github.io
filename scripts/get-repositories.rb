#!/usr/bin/env ruby

# Copyright: (C) 2016 iCub Facility - Istituto Italiano di Tecnologia
# Authors: Ugo Pattacini <ugo.pattacini@iit.it>
# CopyPolicy: Released under the terms of the GNU GPL v3.0.
#
# Dependencies (through gem):
# - octokit
#
# The env variable GITHUB_TOKEN_ORG_READ should contain a valid GitHub
# token with "org:read" permission to retrieve organization data
#
# script for trasversing GitHub pagination
#

require 'octokit'

if ARGV.length < 1 then
  puts "Usage: $0 <organization>"
  exit 1
end

client = Octokit::Client.new
client.org_repos(ARGV[0],{:type => 'public'})

last_response = client.last_response
data=last_response.data
data.each { |x| puts "#{x.name}" }

until last_response.rels[:next].nil?
  last_response = last_response.rels[:next].get
  data=last_response.data
  data.each { |x| puts "#{x.name}" }
end

