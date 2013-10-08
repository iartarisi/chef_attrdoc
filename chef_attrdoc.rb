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
    options[:dir] = d
  end

  opts.on("-f", "--file FILE", "Attributes file to parse") do |f|
    options[:file] = f
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

if options[:file]
  file = File.read(options[:file])
elsif options[:dir]
  file = File.read(File.join(options[:dir], "default.rb"))
else
  file = File.read(File.join("attributes", "default.rb"))
end

class AttributesFile
  def initialize(content)
    @lexed = Ripper.lex(content)
    @groups = []
    @comment = false
    @code = false
    @newline = false

    self.parse
  end

  def end_group
    unless @code.empty?
      @groups << [@code.join, @comment]
    end
    new_group
  end

  def new_group
    @comment = false
    @code = []
    @newline = false
  end

  def parse
    @lexed.each do |loc, token, content|
      case token
      when :on_ignored_nl
        if @comment && @newline
          end_group
        elsif @code.empty?
          new_group
        else
          @newline = true
          if @code
            @code << content
          end
        end
      when :on_nl
        @newline = true
        @code << content if @code
      when :on_comment
        @newline = false
        # ignore foodcritic comments
        next if (
          /^#\s+\:pragma\-foodcritic\: .*$/ =~ content ||
          /^#\s?TODO.*$/ =~ content)

        if @comment
          @comment << content
        else
          @comment = content
          @code = []
        end
      else
        if @code
          @code << content
        end
        @newline = false
      end
    end
    # when there are no newlines at the end of the file, we have to close
    # the code block manually
    unless @code.empty?
      end_group
    end
  end

  def to_s
    @groups.each do |code, doc|
      puts doc.gsub(/^# /, '')
      puts
      puts "```ruby"
      puts code
      puts "```"
      puts
    end
  end
end


attrs = AttributesFile.new(file)
attrs.to_s
