#!/usr/bin/env ruby

# TODO work on newlines :on_nl for comments and for on_ident default

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

def finish_line
  unless $code.empty?
    $groups << [$code, $comment]
  end
  $comment = false
  $code = false
end

lexed.each do |loc, token, content|
  case token
  when :on_ignored_nl
    if $comment
      finish_line
    end
  when :on_comment
    # ignore foodcritic comments
    next if /^#\s+\:pragma\-foodcritic\: .*$/ =~ content

    if $comment
      $comment << content
    else
      $comment = content
      $code = []
    end
  when :on_op
    if content == "=" && $code  # if $code is false, we're at the beginning of the file
      $code << "="
    end
  else
    if $code
      $code << content
    end
  end
end

$groups.each do |cod, doc|
  puts "--------------"
  puts cod.join
  puts
  puts doc
  puts
end
