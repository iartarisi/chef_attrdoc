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


describe ChefAttrdoc::AttributesFile do
  ["TODO bar", "XXX foo bar", "NOTE(me) nasty bug",
    ":pragma-foodcritic: ~FC024 - won't fix this"].each do |comm|
    it "ignores \"#{comm}\" comment" do
      text = <<END
# #{comm}
# good comment
default[good] = 'comment'
END
      ca = ChefAttrdoc::AttributesFile.new(text)
      expect(ca.groups).to eq([["default[good] = 'comment'\n", "# good comment\n"]])
    end
  end

  it 'groups comments and several lines of code together' do
    text = <<END
# first block
default[foo] = 'bar'
default[bar] = 'baz'

# second block
node.set[baz] = 'qux'
node.set[foo] = 'qux'
node.set[bar = 'qux'
END
    ca = ChefAttrdoc::AttributesFile.new(text)
    expect(ca.groups).to eq([
        ["default[foo] = 'bar'\ndefault[bar] = 'baz'\n",
          "# first block\n"],
        ["node.set[baz] = 'qux'\nnode.set[foo] = 'qux'\nnode.set[bar = 'qux'\n",
          "# second block\n"]])
  end

  it 'ignores code without comments' do
    text = <<END
# first block
default[foo] = 'bar'
default[bar] = 'baz'

default[ignored] = false

# second block
node.set[baz] = 'qux'
END
    ca = ChefAttrdoc::AttributesFile.new(text)
    expect(ca.groups).to eq([
        ["default[foo] = 'bar'\ndefault[bar] = 'baz'\n", "# first block\n"],
        ["node.set[baz] = 'qux'\n", "# second block\n"]])
  end

  it 'ignores the first comments in a file' do
    ca = ChefAttrdoc::AttributesFile.new(<<-INPUT)
#!/she/bang

# Copyright
# foo

# this is important
default[foo] = 'bar'
INPUT

    expect(ca.to_s).to eq(<<-OUTPUT)
this is important

```ruby
default[foo] = 'bar'
```

OUTPUT
  end

  it 'handles platform group with lots of branches and hashes' do
    text = <<END
# platform specific attributes
case platform
when "fedora", "redhat", "centos"
  default["openstack"]["identity"]["user"] = "keystone"
  default["openstack"]["identity"]["group"] = "keystone"
  default["openstack"]["identity"]["platform"] = {
    "memcache_python_packages" => [ "python-memcached" ],
    "keystone_packages" => [ "openstack-keystone" ],
    "keystone_process_name" => "keystone-all",
    "package_options" => ""
  }
when "suse"
  default["openstack"]["identity"]["user"] = "openstack-keystone"
  default["openstack"]["identity"]["platform"] = {
    "mysql_python_packages" => [ "python-mysql" ],
    "memcache_python_packages" => [ "python-python-memcached" ],
    "keystone_process_name" => "keystone-all",
    "package_options" => ""
  }
END
    ca = ChefAttrdoc::AttributesFile.new(text)
    expect(ca.to_s).to eq(<<-END)
platform specific attributes

```ruby
case platform
when "fedora", "redhat", "centos"
  default["openstack"]["identity"]["user"] = "keystone"
  default["openstack"]["identity"]["group"] = "keystone"
  default["openstack"]["identity"]["platform"] = {
    "memcache_python_packages" => [ "python-memcached" ],
    "keystone_packages" => [ "openstack-keystone" ],
    "keystone_process_name" => "keystone-all",
    "package_options" => ""
  }
when "suse"
  default["openstack"]["identity"]["user"] = "openstack-keystone"
  default["openstack"]["identity"]["platform"] = {
    "mysql_python_packages" => [ "python-mysql" ],
    "memcache_python_packages" => [ "python-python-memcached" ],
    "keystone_process_name" => "keystone-all",
    "package_options" => ""
  }
```

END
  end

  it 'handles comments over several lines which include blank lines' do
    text = <<END
# my comment
#
# continued comment
#
default["some"]["actual"]["code"] = 42
END
    ca = ChefAttrdoc::AttributesFile.new(text)
    expect(ca.to_s).to eq(<<-END)
my comment

continued comment


```ruby
default["some"]["actual"]["code"] = 42
```

END
  end

  it 'keeps good inline comments' do
    ca = ChefAttrdoc::AttributesFile.new(<<-INPUT)
# my comment
default["ignored"]["thing"] = 33  # a useful inline comment
default["foo"] = "bar"
INPUT
    expect(ca.to_s).to eq(<<-OUTPUT)
my comment

```ruby
default["ignored"]["thing"] = 33  # a useful inline comment
default["foo"] = "bar"
```

OUTPUT
  end

  it 'discards ignored inline comments' do
    ca = ChefAttrdoc::AttributesFile.new(<<-INPUT)
# my comment
default["ignored"]["thing"] = 33  # TODO(tommy) an ignored inline comment
default["foo"] = "bar"
INPUT
    expect(ca.to_s).to eq(<<-OUTPUT)
my comment

```ruby
default["ignored"]["thing"] = 33
default["foo"] = "bar"
```

OUTPUT
  end

  it 'ignores inline comments on code with no leading comments' do
    ca = ChefAttrdoc::AttributesFile.new(<<-INPUT)
# something good
foo = bar

default['something'] = 'bad' # foo
default['just']['more'] = 'code'
INPUT
    expect(ca.to_s).to eq(<<-OUTPUT)
something good

```ruby
foo = bar
```

OUTPUT
  end

  it 'uses isolated comment blocks' do
    ca = ChefAttrdoc::AttributesFile.new(<<-INPUT)
# foo bar
foo = bar

# comment we want to keep
# still good

# foo bar
foo = bar
INPUT
    expect(ca.to_s).to eq(<<-OUTPUT)
foo bar

```ruby
foo = bar
```

comment we want to keep
still good

foo bar

```ruby
foo = bar
```

OUTPUT
  end

  describe 'write_readme' do
    it 'handles an Attributes section followed by a multiword header' do
      readme = double('file').as_null_object
      allow(readme).to receive(:read).and_return(<<-README)

Attributes
==========
my attributes

are nice

Another header
==============
README
      ca = ChefAttrdoc::AttributesFile.new('')
      allow(ca).to receive(:to_s).and_return('foo')
      allow(::File).to receive(:open).and_yield(readme)
      expect(readme).to receive(:write).with("\nAttributes\n==========\nfoo\n")
      ChefAttrdoc.write_readme(ca, 'filename')
    end
  end

  describe 'attrs_contents' do
    it 'reads the files in the directory and returns their contents' do
      expect(ChefAttrdoc.attrs_contents(['spec', 'fixtures']))
        .to eq([["file1.rb", "foo\n"], ["file3.rb", "baz\n"]])
    end
  end

  describe 'process_attributes' do
    it 'reads the files in the directory and processes them' do
      allow(ChefAttrdoc).to receive(:attrs_contents).with('foodir')
        .and_return([["file1.rb", "foo\n"], ["file3.rb", "baz\n"]])
      expect(ChefAttrdoc.process_attributes('foodir'))
        .to eq(<<-OUTPUT)
## file1.rb

foo

## file3.rb

baz
OUTPUT
    end
  end
end
