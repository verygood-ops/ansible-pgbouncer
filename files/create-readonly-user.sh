#!/bin/sh

# script to create periscope user with read-only permissions

set -x -e

usage() { echo "Usage: PGPASSWORD=foo $0 -d db-name -p port -U superuser -u readonly_user -P readonly_user_password -s 'schema schema2' -t 'table table2'" 1>&2; exit 1; }

while getopts ":d:p:U:u:P:h:s:t:" o; do
    case "${o}" in
        d)
            DB_NAME=${OPTARG}
            ;;
        p)
            PORT=${OPTARG}
            ;;
        U)
            ADMIN_USER=${OPTARG}
            ;;            
        u)
            READ_ONLY_USER=${OPTARG}
            ;;
        P)
            READ_ONLY_USER_PASSWORD=${OPTARG}
            ;;
        h)
            HOSTNAME=${OPTARG}
            ;;
        s)
            SCHEMAS=${OPTARG}
            ;;
        t)
            TABLES=${OPTARG}
            ;;            
        *)
            usage
            ;;
    esac
done

# psql_command admin_user "command"
function psql_command() {
    psql -h$HOSTNAME \
      -p$PORT $DB_NAME \
      -U$ADMIN_USER \
      -c "$1"
}

# create role
psql_command "create role \"$READ_ONLY_USER\" login encrypted password '$READ_ONLY_USER_PASSWORD';"
psql_command "grant connect on database \"$DB_NAME\" to \"$READ_ONLY_USER\";"

# grant usage to schemas
for schema in $SCHEMAS
do
    psql_command "grant usage on schema $schema to \"$READ_ONLY_USER\";"
done

# grant read-only permissions to following tables
for table in $TABLES
do
    psql_command "grant select on $table to \"$READ_ONLY_USER\";"
done
