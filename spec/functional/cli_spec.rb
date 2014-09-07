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

describe 'chef_attrdoc' do
  it 'shows version' do
    output = `ruby -Ilib bin/chef_attrdoc --version`
    expect(output).to match(/chef_attrdoc \d+\.\d+\.\d+/)
  end
end
