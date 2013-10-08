#!/usr/bin/env ruby

# TODO work on newlines :on_nl for comments and for on_ident default

require 'ripper'

file = File.read('default.rb')
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
