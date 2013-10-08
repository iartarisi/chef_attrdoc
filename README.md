chef-attrdoc
============

extract documentation from chef cookbooks' attributes files and output it to the README


chef-attrdoc groups attribute initialization lines together with the comments immediately above them. Any lines containing an attribute initialization which are not separated by two newlines are considered a group. The comment immediately above them is assumed to describe the group of attributes below. Groups of attribute initialization lines which are not immediately preceded by a comment line are ignored and will not show up in the output.

chef-attrdoc currently ignores *TODO* and *foodcritic* comments.

Usage:

```
# gem install chef_attrdoc
# attr_doc -d ~/cookbooks/mycookbook
```