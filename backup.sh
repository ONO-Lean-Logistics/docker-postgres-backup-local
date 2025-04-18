#! /bin/sh

set -e

if [ "${POSTGRES_DB}" = "**None**" -a "${POSTGRES_DB_FILE}" = "**None**" ]; then
  echo "You need to set the POSTGRES_DB or POSTGRES_DB_FILE environment variable."
  exit 1
fi

if [ "${POSTGRES_HOST}" = "**None**" ]; then
  if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
    POSTGRES_HOST=${POSTGRES_PORT_5432_TCP_ADDR}
    POSTGRES_PORT=${POSTGRES_PORT_5432_TCP_PORT}
  else
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ "${POSTGRES_USER}" = "**None**" -a "${POSTGRES_USER_FILE}" = "**None**" ]; then
  echo "You need to set the POSTGRES_USER or POSTGRES_USER_FILE environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" -a "${POSTGRES_PASSWORD_FILE}" = "**None**" -a "${POSTGRES_PASSFILE_STORE}" = "**None**" ]; then
  echo "You need to set the POSTGRES_PASSWORD or POSTGRES_PASSWORD_FILE or POSTGRES_PASSFILE_STORE environment variable or link to a container named POSTGRES."
  exit 1
fi

#Process vars
if [ "${POSTGRES_DB_FILE}" = "**None**" ]; then
  POSTGRES_DBS=$(echo "${POSTGRES_DB}" | tr , " ")
elif [ -r "${POSTGRES_DB_FILE}" ]; then
  POSTGRES_DBS=$(cat "${POSTGRES_DB_FILE}")
else
  echo "Missing POSTGRES_DB_FILE file."
  exit 1
fi
if [ "${POSTGRES_USER_FILE}" = "**None**" ]; then
  export PGUSER="${POSTGRES_USER}"
elif [ -r "${POSTGRES_USER_FILE}" ]; then
  export PGUSER=$(cat "${POSTGRES_USER_FILE}")
else
  echo "Missing POSTGRES_USER_FILE file."
  exit 1
fi
if [ "${POSTGRES_PASSWORD_FILE}" = "**None**" -a "${POSTGRES_PASSFILE_STORE}" = "**None**" ]; then
  export PGPASSWORD="${POSTGRES_PASSWORD}"
elif [ -r "${POSTGRES_PASSWORD_FILE}" ]; then
  export PGPASSWORD=$(cat "${POSTGRES_PASSWORD_FILE}")
elif [ -r "${POSTGRES_PASSFILE_STORE}" ]; then
  export PGPASSFILE="${POSTGRES_PASSFILE_STORE}"
else
  echo "Missing POSTGRES_PASSWORD_FILE or POSTGRES_PASSFILE_STORE file."
  exit 1
fi
export PGHOST="${POSTGRES_HOST}"
export PGPORT="${POSTGRES_PORT}"
KEEP_DAYS=${BACKUP_KEEP_DAYS}
KEEP_WEEKS=`expr $(((${BACKUP_KEEP_WEEKS} * 7) + 1))`
KEEP_MONTHS=`expr $(((${BACKUP_KEEP_MONTHS} * 31) + 1))`

#Initialize dirs
mkdir -p "${BACKUP_DIR}/daily/" "${BACKUP_DIR}/weekly/" "${BACKUP_DIR}/monthly/"

#Loop all databases
for DB in ${POSTGRES_DBS}; do
  #Initialize filename vers
  DFILE="${BACKUP_DIR}/daily/${DB}-`date +%Y%m%d-%H%M%S`${BACKUP_SUFFIX}"
  WFILE="${BACKUP_DIR}/weekly/${DB}-`date +%G%V`${BACKUP_SUFFIX}"
  MFILE="${BACKUP_DIR}/monthly/${DB}-`date +%Y%m`${BACKUP_SUFFIX}"
  #Create dump
  if [ "${POSTGRES_CLUSTER}" = "TRUE" ]; then
    echo "Creating cluster dump of ${DB} database from ${POSTGRES_HOST}..."
    pg_dumpall -l "${DB}" ${POSTGRES_EXTRA_OPTS} | gzip > "${DFILE}"
  else
    echo "Creating dump of ${DB} database from ${POSTGRES_HOST}..."
    pg_dump -d "${DB}" -f "${DFILE}" ${POSTGRES_EXTRA_OPTS}
  fi
  #Copy (hardlink) for each entry
  if [ -d "${DFILE}" ]; then
    if [ ! -e "${WFILE}" ]; then
      cp -r "${DFILE}" "${WFILE}"
    fi
    if [ ! -e "${MFILE}" ]; then
      cp -r "${DFILE}" "${MFILE}"
    fi
  else
    if [ ! -e "${WFILE}" ]; then
      ln -v "${DFILE}" "${WFILE}"
    fi
    if [ ! -e "${MFILE}" ]; then
      ln -v "${DFILE}" "${MFILE}"
    fi
  fi

  #Clean old files

  echo "Cleaning older than ${KEEP_DAYS} days for ${DB} database from ${POSTGRES_HOST}..."
  find "${BACKUP_DIR}/daily" -maxdepth 1 -mtime +${KEEP_DAYS} -name "${DB}-*${BACKUP_SUFFIX}" -exec rm -rf '{}' ';'
  find "${BACKUP_DIR}/weekly" -maxdepth 1 -mtime +${KEEP_WEEKS} -name "${DB}-*${BACKUP_SUFFIX}" -exec rm -rf '{}' ';'
  find "${BACKUP_DIR}/monthly" -maxdepth 1 -mtime +${KEEP_MONTHS} -name "${DB}-*${BACKUP_SUFFIX}" -exec rm -rf '{}' ';'

  if [ "${BACKUP_KEEP_N_DAILY}" != "**None**" ]; then
    echo "Cleaning those that are not the most recent ${BACKUP_KEEP_N_DAILY} daily for ${DB} database from ${POSTGRES_HOST}..."
    find "${BACKUP_DIR}/daily" -maxdepth 1 -name "${DB}-*${BACKUP_SUFFIX}" -printf "%T@ %p\n" \
      | sort -nr | cut -d " " -f2 | tail -n +$(($BACKUP_KEEP_N_DAILY+1)) | xargs rm -rf
  fi

  if [ "${BACKUP_KEEP_N_WEEKLY}" != "**None**" ]; then
    echo "Cleaning those that are not the most recent ${BACKUP_KEEP_N_WEEKLY} weekly for ${DB} database from ${POSTGRES_HOST}..."
    find "${BACKUP_DIR}/weekly" -maxdepth 1 -name "${DB}-*${BACKUP_SUFFIX}" -printf "%T@ %p\n" \
      | sort -nr | cut -d " " -f2 | tail -n +$(($BACKUP_KEEP_N_WEEKLY+1)) | xargs rm -rf
  fi

  if [ "${BACKUP_KEEP_N_MONTHLY}" != "**None**" ]; then
    echo "Cleaning those that are not the most recent ${BACKUP_KEEP_N_MONTHLY} monthly for ${DB} database from ${POSTGRES_HOST}..."
    find "${BACKUP_DIR}/monthly" -maxdepth 1 -name "${DB}-*${BACKUP_SUFFIX}" -printf "%T@ %p\n" \
      | sort -nr | cut -d " " -f2 | tail -n +$(($BACKUP_KEEP_N_MONTHLY+1)) | xargs rm -rf
  fi
done

echo "SQL backup created successfully"
