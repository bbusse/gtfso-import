#!/usr/bin/env bash
#
# gtfso-import
#
# Imports General Transit Feed Specification
# (gtfs) data into PostgreSQL
#
# © 2022 Björn Busse (see also: LICENSE)
# bj.rn@baerlin.eu
#

set -eo pipefail

WORKDIR="/import"
SQL_FILE="gtfs_psql.sql"
CREATE_DB=1
DROP_DB=0

declare -a CSV_FILES=("agency.txt" \
                      "calendar.txt" \
                      "calendar_dates.txt" \
                      "routes.txt" \
                      "stop_times.txt" \
                      "stops.txt" \
                      "transfers.txt" \
                      "trips.txt")

function psql_drop_database() {
    local host
    host="${1}"
    local user
    user="${2}"
    local db
    db="${3}"

    if ! psql -U "${user}" -h "${host}" -d "${db}" \
              -c "DROP ${db} WITH (FORCE)"; then
        printf "gtfso: Failed to drop database\nAborting..\n"
        exit 1
    fi
}

function psql_create_database() {
    local host
    host="${1}"
    local user
    user="${2}"
    local db
    db="${3}"

    if ! createdb -U "${user}" -h "${host}" "${db}"; then
        printf "gtfso: Failed to create database\n"
    fi
}


function psql_truncate_table() {
    local host
    host="${1}"
    local user
    user="${2}"
    local db
    db="${3}"
    local table
    table="${4}"

    if ! psql -U "${user}" -h "${host}" -d "${db}" \
              -c "TRUNCATE ${table}"; then
        printf "gtfso: Failed to truncate table\nAborting..\n"
        exit 1
    fi
}

function psql_import_csv() {
    local host
    host="${1}"
    local user
    user="${2}"
    local db
    db="${3}"
    local table
    table="${4}"
    local file
    file="${5}"

    if ! psql -U "${user}" -h "${host}" -d "${db}" \
              -c "\COPY ${table} FROM '${file}' WITH DELIMITER AS ',' CSV HEADER"; then
        printf "gtfso: Failed to import data from %s\n" "${file}"
        exit 1
    fi
}

function psql_run_sql() {
    local host
    host="${1}"
    local user
    user="${2}"
    local db
    db="${3}"
    local file
    file="${4}"

    if ! psql -U "${user}" -h "${host}" -d "${db}" -a -f "${file}"; then
        printf "gtfso: Failed to import data\n"
        exit 1
    fi
}

function gtfs_fetch_data() {
    local url
    url="${1}"
    local path
    path="${2}"

    curl -LO -s -S --fail --output-dir "${path}" "${url}"

    printf "gtfso: Extracting data..\n"
    unzip -q -d "${path}" "${path}"/vbbgtfs
}

function main() {
    local t0
    t0=$(date +%s)

    if [ -z ${DB_NAME+x} ]; then
        printf "gtfso: Please specify the database host to connect to via DB_NAME\nAborting.."
        exit 1
    fi

    printf "gtfso: Fetching gtfs data..\n"
    gtfs_fetch_data "${URL_DATA}" "${WORKDIR}"

    if [ $DROP_DB -eq 1 ]; then
        printf "gtfso: Dropping database..\n"
        psql_drop_database "${DB_HOST}" \
                           "${DB_USER}" \
                           "${DB_NAME}"
    fi

    if [ $CREATE_DB -eq 1 ]; then
        printf "gtfso: Creating database..\n"
        psql_create_database "${DB_HOST}" \
                             "${DB_USER}" \
                             "${DB_NAME}"
    fi

    printf "\n"
    printf "gtfso: Creating tables..\n"
    psql_run_sql "${DB_HOST}" \
                 "${DB_USER}" \
                 "${DB_NAME}" \
                 "${WORKDIR}"/"${SQL_FILE}" \
                 1

    for file in "${CSV_FILES[@]}"; do
        local table
        table=${file%%.*}

        printf "Truncating: %s\n" "${table}"
        psql_truncate_table "${DB_HOST}" \
                            "${DB_USER}" \
                            "${DB_NAME}" \
                            "${table}"

        printf "Importing from: %s\n" "${file}"
        psql_import_csv "${DB_HOST}" \
                        "${DB_USER}" \
                        "${DB_NAME}" \
                        "${table}" \
                        "${WORKDIR}/${file}"
    done

    t_duration=$(($(date +%s) - t0))

    printf "gtfso: Import took %s seconds\n" "${t_duration}"
    printf "gtfso: Done.\n"
}

main "@"
