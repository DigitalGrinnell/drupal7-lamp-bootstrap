#!/bin/bash

# Lifted from https://gist.github.com/pkuczynski/8665367
# Note that in this form only a simple YAML file is supported...
#  - No arrays, only simple key:value pairs
#  - No other operators
#  - Indent using 2 spaces only!

parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}


# Example uses follow...
#

: <<'END'
test.sh
---------------------
#!/bin/sh

# include parse_yaml function
. parse_yaml.sh

# read yaml file
eval $(parse_yaml zconfig.yml)

# access yaml content
echo $development_database    ...produces 'my_database'

zconfig.yml
----------------------
development:
  adapter: mysql2
  encoding: utf8
  database: my_database
  username: root
  password:

END
