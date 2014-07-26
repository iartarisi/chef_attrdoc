# Copyright 1970, nobody

# this is the attribute
default['some']['attribute'] = 'foo'

default['this']['will']['be'] = 'ignored'

# NOTE code blocks without a comment are ignored as are those beginning
# NOTE with 'NOTE', 'XXX', 'TODO' or foodcritic comments

# a longer block of code
case something
when 'foo'
  default['some']['foo'] = 'baz'
else
  default['some']['foo'] = 'qux'
end
