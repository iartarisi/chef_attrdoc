chef-attrdoc
============

extract documentation from chef cookbooks' attributes files and output it to the README


chef-attrdoc groups attribute initialization lines together with the comments immediately above them. Any lines containing an attribute initialization which are not separated by two newlines are considered a group. The comment immediately above them is assumed to describe the group of attributes below. Groups of attribute initialization lines which are not immediately preceded by a comment line are ignored and will not show up in the output.

chef-attrdoc currently ignores *TODO* and *foodcritic* comments.

### Usage:

```
# gem install chef_attrdoc
# attr_doc -d ~/cookbooks/mycookbook
```

### Examples

Here are some example outputs from openstack chef cookbooks:

[openstack-compute attributes file](https://github.com/stackforge/cookbook-openstack-compute/blob/aa42f5c09a445cde7267e4b4d00a6ce893aa481e/attributes/default.rb) - [output](https://gist.github.com/mapleoin/6886586)
[openstack-identity attributes file](https://github.com/stackforge/cookbook-openstack-identity/blob/2e6b8b9c6788ae28fbc362c77c53a51c040b49a6/attributes/default.rb) - [output](https://gist.github.com/mapleoin/6886493)