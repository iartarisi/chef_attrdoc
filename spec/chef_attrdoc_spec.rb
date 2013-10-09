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

require 'chef_attrdoc'


describe ChefAttrdoc do
  ["TODO bar", "XXX foo bar", "NOTE(me) nasty bug",
    ":pragma-foodcritic: ~FC024 - won't fix this"].each do |comm|
    it "should ignore \"#{comm}\" comment" do
      text = <<END
# #{comm}
# good comment
default[good] = 'comment'
END
      ca = ChefAttrdoc::AttributesFile.new(text)
      expect(ca.groups).to eq([["default[good] = 'comment'\n", "# good comment\n"]])
    end
  end
end
