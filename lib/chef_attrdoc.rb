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

require 'ripper'

module ChefAttrdoc
  class AttributesFile

    attr_reader :groups

    def initialize(content)
      @lexed = Ripper.lex(content)
      @groups = []
      @comment = false
      @code = []
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
          if ignored_comments(content)
            # inline comments
            # go back to the existing code and remove the trailing
            # whitespace, but give it the newline which the lexer
            # considers part of the comment
            if !@code.empty?
              @code[-1].strip!
              @code << "\n"
            end

            next
          end

          if @comment
            # since we can only have one comment per block (and we put
            # that at the top, before the code), keep appending to that
            # until the code starts. When the code starts, just leave
            # comments where we find them, in the code.
            if @code.empty?
              @comment << content
            else
              @code << content
            end
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
      strings = []
      @groups.each do |code, doc|
        strings << doc.gsub(/^#[[:blank:]]*/, '')
        strings << "\n"
        strings << "```ruby\n"
        strings << code
        strings << "```\n\n"
      end
      strings.join
    end

    def to_readme(readme)
      File.open(readme, File::RDWR) do |f|
        # XXX find a cleaner way and do this in one step
        content = f.read
        if content =~ /\nAttributes\s*=+\s*\n/
          updated = content.gsub(/(.*\nAttributes\s*=+\s*\n)(.+?)(\n\w+\s*\n=+.*)/m,
            '\1CHEF_ATTRDOC_UPDATING_TEMPLATE\3')
        elsif content =~ /\n[#]+\s*Attributes\s*\n/
          updated = content.gsub(/(?<before>.*\n(?<header>[#]+)\s*Attributes\s*\n)(.+?)(?<after>\n\k<header>\s*\w+\s*\n.*)/m,
            '\k<before>CHEF_ATTRDOC_UPDATING_TEMPLATE\k<after>')
        else
          raise StandardError, "Could not find Attributes heading in #{readme}. Please make sure your README file has proper markdown formatting and includes an Attributes heading."
        end

        updated.sub! 'CHEF_ATTRDOC_UPDATING_TEMPLATE', self.to_s
        f.rewind
        f.write(updated)
        f.flush
        f.truncate(f.pos)
      end
    end
  end
end

def ignored_comments(content)
  (/^#\s+\:pragma\-foodcritic\: .*$/ =~ content ||
    /^#\s?(TODO|XXX|NOTE).*$/ =~ content)
end
