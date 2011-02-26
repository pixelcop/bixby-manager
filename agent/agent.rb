#!/usr/bin/ruby

require 'rubygems'
require 'bundler/setup'
Bundler.setup(:default)

require 'json'

AGENT_ROOT = File.expand_path(File.dirname(__FILE__))

require AGENT_ROOT + '/lib/agent'
require AGENT_ROOT + '/lib/rpc'
require AGENT_ROOT + '/lib/rpc-json'
require AGENT_ROOT + '/lib/app'

App.run!
