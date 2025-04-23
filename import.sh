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

# Set WORKDIR only if it is not already set
WORKDIR="${WORKDIR:-/import}"
SQL_FILE="../gtfs_psql.sql"
SQL_FILE_ROUTE_TYPES="../gtfs_route_types_psql.sql"
CREATE_DB=1
DROP_DB=0

export PGPASSWORD="$DB_PASS"

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

    if ! PGPASSWORD="${DB_PASSWORD}" psql -U "${user}" -h "${host}" -d "${db}" \
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
    local locale
    locale="${4}"

    if ! PGPASSWORD="${DB_PASSWORD}" createdb -U "${user}" -h "${host}" "${db}" -l "${locale}" -T template0; then
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

    if ! PGPASSWORD="${DB_PASSWORD}" psql -U "${user}" -h "${host}" -d "${db}" \
              -c "DO \$\$ BEGIN IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = '${table}') THEN TRUNCATE ${table}; END IF; END \$\$;"; then
        printf "gtfso: Failed to truncate table or table does not exist\nAborting..\n"
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

    if ! PGPASSWORD="${DB_PASSWORD}" psql -U "${user}" -h "${host}" -d "${db}" \
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

    if ! PGPASSWORD="${DB_PASSWORD}" psql -U "${user}" -h "${host}" -d "${db}" -a -f "${file}"; then
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
    unzip -oq -d "${path}" "${path}"/vbbgtfs # Added '-o' to overwrite existing files
}

function check_required_tools() {
    local tools=("psql" "createdb" "curl" "unzip")
    for tool in "${tools[@]}"; do
        if ! command -v "${tool}" &> /dev/null; then
            printf "gtfso: Required tool '%s' is not installed. Aborting...\n" "${tool}"
            exit 1
        fi
    done
}

function main() {
    check_required_tools

    local t0
    t0=$(date +%s)

    if [ -z ${DB_HOST+x} ]; then
        printf "gtfso: Please specify the database host "
        printf "to connect to via DB_HOST\nAborting.."
        exit 1
    fi

    if [ -z ${DB_USER+x} ]; then
        printf "gtfso: Please specify the database user "
        printf "to connect with via DB_USER\nAborting.."
        exit 1
    fi

    if [ -z ${DB_NAME+x} ]; then
        printf "gtfso: Please specify the database "
        printf "to connect to via DB_NAME\nAborting.."
        exit 1
    fi

    printf "gtfso: Fetching gtfs data..\n"
    gtfs_fetch_data "${URL_DATA}" "${WORKDIR}"

    # Set default locale if not given
    if [ -z ${DB_LOCALE+x} ]; then
        DB_LOCALE="de_DE.UTF-8"
    fi

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
                             #"${DB_LOCALE}"
    fi

    printf "gtfso: Creating tables..\n"
    psql_run_sql "${DB_HOST}" \
                 "${DB_USER}" \
                 "${DB_NAME}" \
                 "${SQL_FILE}" \
                 1

    printf "Truncating: route_types\n"
    psql_truncate_table "${DB_HOST}" \
                        "${DB_USER}" \
                        "${DB_NAME}" \
                        "route_types"

    # Create route_types table and import data
    psql_run_sql "${DB_HOST}" \
                 "${DB_USER}" \
                 "${DB_NAME}" \
                 "${SQL_FILE_ROUTE_TYPES}" \
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
