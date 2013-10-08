#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# Copyright 2013, Ionuț Arțăriși <ionut@artarisi.eu>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'optparse'
require 'ripper'

options = {}

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: chef_attrdoc.rb [options]"

  opts.on("-d", "--directory DIR", "Cookbook directory (defaults to current dir)") do |d|
    options[:directory] = d
  end

  opts.on("-f", "--file FILE", "Attributes file to parse") do |f|
    options[:file] = f
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

file = File.read(options[:file])
lexed = Ripper.lex(file)

$groups = []

$comment = false
$code = false

def end_group
  unless $code.empty?
    $groups << [$code.join, $comment]
  end
  $comment = false
  $code = false
end

lexed.each do |loc, token, content|
  case token
  when :on_ignored_nl
    if $comment
      end_group
    end
  when :on_comment
    # ignore foodcritic comments
    next if (
      /^#\s+\:pragma\-foodcritic\: .*$/ =~ content ||
      /^#\s?TODO.*$/ =~ content)

    if $comment
      $comment << content
    else
      $comment = content
      $code = []
    end
  else
    if $code
      $code << content
    end
  end
end

$groups.each do |code, doc|
  puts doc.gsub(/^# /, '')
  puts
  puts "```ruby"
  puts code
  puts "```"
  puts
end
