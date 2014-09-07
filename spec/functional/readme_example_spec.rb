# -*- coding: utf-8 -*-

# Copyright 2014, Ionuț Arțăriși <ionut@artarisi.eu>
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

describe 'This is the example from chef_attrdoc\'s README.md' do
  it 'prints the right attributes section when used with --stdout' do
    output = `ruby -Ilib bin/chef_attrdoc spec/fixtures/cookbook-example/ -s`
    expect(output).to eq(<<-OUTPUT)
## default.rb

this is the attribute

```ruby
default['some']['attribute'] = 'foo'
```

a longer block of code

```ruby
case something
when 'foo'
  default['some']['foo'] = 'baz'
else
  default['some']['foo'] = 'qux'
end
```

OUTPUT
  end

  it 'prints the right output when used with --dry-run' do
    output = `ruby -Ilib bin/chef_attrdoc spec/fixtures/cookbook-example/ --dry-run`
    expect(output).to eq(<<-OUTPUT)
chef_attrdoc example README
===========================

This is just an example

Attributes
==========

## default.rb

this is the attribute

```ruby
default['some']['attribute'] = 'foo'
```

a longer block of code

```ruby
case something
when 'foo'
  default['some']['foo'] = 'baz'
else
  default['some']['foo'] = 'qux'
end
```


License
=======
This is usually important.
OUTPUT
  end

  describe 'tests which change the README.md fixture' do
    let(:readme) { 'spec/fixtures/cookbook-example/README.md' }
    before do
      @backup = File.read(readme)
    end

    after do
      File.open(readme, 'w') do |f|
        f.write(@backup)
      end
    end

    it 'changes the README file appropriately when invoked with no args' do
      output = `ruby -Ilib bin/chef_attrdoc spec/fixtures/cookbook-example/`
      expect(output).to be_empty
      expect(File.read('spec/fixtures/cookbook-example/README.md')).to eq(<<-OUT)
chef_attrdoc example README
===========================

This is just an example

Attributes
==========

## default.rb

this is the attribute

```ruby
default['some']['attribute'] = 'foo'
```

a longer block of code

```ruby
case something
when 'foo'
  default['some']['foo'] = 'baz'
else
  default['some']['foo'] = 'qux'
end
```


License
=======
This is usually important.
OUT
    end
  end
end
