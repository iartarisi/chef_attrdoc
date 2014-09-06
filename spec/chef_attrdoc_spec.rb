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

require 'chef_attrdoc'


describe ChefAttrdoc do
  describe '#write_readme' do
    context 'using Attributes\n========== syntax' do
      it 'handles an Attributes section followed by a multiword header' do
        readme = double('file').as_null_object
        allow(readme).to receive(:read).and_return(<<-README)

Attributes
==========
my attributes

are nice

Another header
==============

doc we won't touch

README
        allow(::File).to receive(:open).and_yield(readme)
        expect(readme).to receive(:write).with(<<-README)

Attributes
==========

foo

Another header
==============

doc we won't touch

README
        ChefAttrdoc.write_readme('filename', "foo\n")
      end

      it 'normalizes space after an Attributes section' do
        readme = double('file').as_null_object
        allow(readme).to receive(:read).and_return(<<-README)

Attributes
==========



my attributes

are nice

Another header
==============

doc we won't touch

README
        allow(::File).to receive(:open).and_yield(readme)
        expect(readme).to receive(:write).with(<<-README)

Attributes
==========

foo

Another header
==============

doc we won't touch

README
        ChefAttrdoc.write_readme('filename', "foo\n")
      end
    end
    context 'using ### Attributes syntax' do
      it 'handles an Attributes section followed by a multiword header' do
        readme = double('file').as_null_object
        allow(readme).to receive(:read).and_return(<<-README)

## Attributes
my attributes

are nice

## Another header

doc we won't touch
README
        allow(::File).to receive(:open).and_yield(readme)
        expect(readme).to receive(:write).with(<<-README)

## Attributes

foo

## Another header

doc we won't touch
README
        ChefAttrdoc.write_readme('filename', "foo\n")
      end

      it 'normalizes space after an Attributes section' do
        readme = double('file').as_null_object
        allow(readme).to receive(:read).and_return(<<-README)

## Attributes



my attributes

are nice

## Another header

doc we won't touch
README
        allow(::File).to receive(:open).and_yield(readme)
        expect(readme).to receive(:write).with(<<-README)

## Attributes

foo

## Another header

doc we won't touch
README
        ChefAttrdoc.write_readme('filename', "foo\n")
      end
    end
  end

  describe '#attrs_contents' do
    it 'reads the files in the directory and returns their contents' do
      expect(ChefAttrdoc.attrs_contents(['spec', 'fixtures']))
        .to eq([["file1.rb", "foo\n"], ["file3.rb", "baz\n"]])
    end
  end

  describe '#process_attributes' do
    it 'reads the files in the directory and processes them' do
      allow(ChefAttrdoc).to receive(:attrs_contents).with('foodir')
        .and_return([["file1.rb", "foo\n"], ["file3.rb", "baz\n"]])

      allow_any_instance_of(ChefAttrdoc::AttributesFile).to receive(:to_s)
        .and_return("qux\n")
      expect(ChefAttrdoc.process_attributes('foodir'))
        .to eq(<<-OUTPUT)
## file1.rb

qux

## file3.rb

qux
OUTPUT
    end
  end
end
