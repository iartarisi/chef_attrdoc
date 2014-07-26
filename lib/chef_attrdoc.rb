# -*- coding: utf-8 -*-

# Copyright 2013-2014, Ionuț Arțăriși <ionut@artarisi.eu>
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
      if @comment
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
      @lexed.each do |(lineno, column), token, content|
        case token
        # Ignored newlines occur when a newline is encountered, but
        # the statement that was expressed on that line was not
        # completed on that line.
        when :on_ignored_nl
          # end a group if we've reached an empty line after a comment
          if @comment && @newline
            end_group
          else
            @newline = true
            @code << content
          end
        # This is the first thing that exists on a new line–NOT the last!
        when :on_nl
          @newline = true
          @code << content
        when :on_comment
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
            # After the code has started, leave the inline comments
            # where we found them, but ignore the ones below the
            # code. Those are usually garbage. We do this by ending the
            # current group when we encounter them.
            if !@code.empty? && @newline
              end_group
              @comment = ''
            end
            # Since we can only have one comment per block (which we put
            # at the top, before the code), keep appending to that
            # until the code starts.
            if @code.empty?
              @comment << content
            else
              # inline comments
              @code << content
            end
          elsif column == 0
            @comment = content
            @code = []
          end

          @newline = false
        else
          @code << content
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
      # ignore the starting comments in a file, these are usually
      # shebangs, copyright statements, encoding declarations etc.
      @groups = @groups.drop_while{|code, doc| /\A[[:space:]]*\z/.match code}

      @groups.each do |code, doc|
        strings << doc.gsub(/^#[[:blank:]]*/, '')
        strings << "\n"
        unless /\A[[:space:]]*\z/.match code
          strings << "```ruby\n"
          strings << code
          strings << "```\n\n"
        end
      end
      strings.join
    end
  end

  # open the :readme: Markdown file and replace the 'Attributes' section
  # with the contents of :parsed:
  def self.write_readme(readme, parsed)
    File.open(readme, File::RDWR) do |f|
      # TODO find a cleaner way and do this in one step
      content = f.read
      if content =~ /\nAttributes\s*=+\s*\n/
        updated = content.gsub(/(?<before>.*\nAttributes\s*=+\s*\n)(?m:.+?)(?<after>\n.+\s*\n=+.*)/,
          '\k<before>CHEF_ATTRDOC_UPDATING_TEMPLATE\k<after>')

        # XXX hack because I couldn't figure out how to get another
        # newline in between the <before> and the content
        updated.sub!('CHEF_ATTRDOC_UPDATING_TEMPLATE',
          "\nCHEF_ATTRDOC_UPDATING_TEMPLATE")
      elsif content =~ /\n\#+\s*Attributes\s*\n/
        updated = content.gsub(/(?<before>.*\n\#+\s*Attributes\s*\n)(.+?)(?<after>\n\#+.*)/m,
          '\k<before>CHEF_ATTRDOC_UPDATING_TEMPLATE\k<after>')
      else
        raise StandardError, "Could not find Attributes heading in #{readme}. Please make sure your README file has proper markdown formatting and includes an Attributes heading."
      end

      updated.sub! 'CHEF_ATTRDOC_UPDATING_TEMPLATE', parsed
      f.rewind
      f.write(updated)
      f.flush
      f.truncate(f.pos)
    end
  end

  # return a list of [filename, file-contents] for each ruby file in :dir:
  def self.attrs_contents(dir)
    files_contents = []
    filenames = Dir.glob(File.join(dir, '*.rb')).sort

    filenames.each do |f|
      begin
        files_contents << [File.basename(f), IO.read(f)]
      rescue Exception => e
        abort e.message
      end
    end

    files_contents
  end

  # takes a directory of attributes files and returns a string with
  # Markdown content with the output of processing all the attributes
  def self.process_attributes(dir)
    files_contents = ChefAttrdoc.attrs_contents dir

    output = []
    files_contents.each do |filename, contents|
      attrs = ChefAttrdoc::AttributesFile.new contents
      output << "## #{filename}\n\n#{attrs}"
    end

    output.join("\n")
  end
end

def ignored_comments(content)
  (/^#\s+\:pragma\-foodcritic\: .*$/ =~ content ||
    /^#\s?(TODO|XXX|NOTE).*$/ =~ content)
end
