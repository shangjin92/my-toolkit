#!/bin/bash

export PGHOST=
export PGPORT=
export PGUSER=
PGOPTIONS=--search_path=prod psql -d test-db --pset=pager=off <<EOF
    create table if not exists test_table (
        id           bigserial    not null
            constraint test_table_pk
                primary key,
        gmt_create   timestamp  not null default now(),
        gmt_modified timestamp  not null default now()
    );
EOF

exclude_db_names=(postgres template0 template1)
echo '\l' | psql postgresql://${PGHOST}:${PGPORT}/postgres -U ${PGUSER} | sed '1,3d' |grep '^ [a-zA-Z0-9]' |awk '{print $1}' |while read db_name; do
    if [[ ${exclude_db_names[@]/${db_name}/} != ${exclude_db_names[@]} ]]; then
        echo "$db_name no backup."
    else
        pg_dump -F c -b -v -f data.dat ${db_name}
    fi

     if [[ $? != 0 ]];then
        >&2 echo "backup database: ${db_name} failed."
    fi
done
