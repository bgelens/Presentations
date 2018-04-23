# switch to bash

# enter chef demo folder
cd 01\ -\ Chef/chef-starter/chef-repo/

# generate cookbook
# chef generate cookbook cookbooks/PSCONFEU
: << COMMENT
Generating cookbook PSCONFEU
- Ensuring correct cookbook file content
- Committing cookbook files to git
- Ensuring delivery configuration
- Ensuring correct delivery build cookbook content
- Adding delivery configuration to feature branch
- Adding build cookbook to feature branch
- Merging delivery content feature branch to master
COMMENT

# show recipes
code ./cookbooks/PSCONFEU/recipes/containerHost.rb
code ./cookbooks/PSCONFEU/recipes/containerTcpOnly.rb

# upload cookbook to chef server
# knife cookbook upload PSCONFEU

# show cookbook in portal

# to find out about which cookbooks are present via knife
# knife cookbook list

# to get the content of the default recipe
# knife cookbook show PSCONFEU 0.1.0 recipes containerTcpOnly.rb
