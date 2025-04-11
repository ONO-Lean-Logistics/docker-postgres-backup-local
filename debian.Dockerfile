ARG BASETAG=latest
FROM postgres:$BASETAG

ARG GOCRONVER=v0.0.10
ARG TARGETOS
ARG TARGETARCH

# Fix Debian repositories for EOL versions (Stretch, Jessie, etc.)
RUN set -x \
    # Update sources.list for Stretch (Debian 9)
    && if [ -f /etc/os-release ] && grep -q "stretch" /etc/os-release; then \
         echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list \
         && echo "deb http://archive.debian.org/debian-security stretch/updates main" >> /etc/apt/sources.list \
         && echo "Acquire::Check-Valid-Until false;" > /etc/apt/apt.conf.d/99no-check-valid-until; \
    # Update sources.list for Jessie (Debian 8)
    elif [ -f /etc/os-release ] && grep -q "jessie" /etc/os-release; then \
         echo "deb http://archive.debian.org/debian jessie main" > /etc/apt/sources.list \
         && echo "deb http://archive.debian.org/debian-security jessie/updates main" >> /etc/apt/sources.list \
         && echo "Acquire::Check-Valid-Until false;" > /etc/apt/apt.conf.d/99no-check-valid-until; \
    fi \
    # Disable PostgreSQL-specific repository (apt.postgresql.org) if it exists
    && if [ -f /etc/apt/sources.list.d/pgdg.list ]; then \
         mv /etc/apt/sources.list.d/pgdg.list /etc/apt/sources.list.d/pgdg.list.bak; \
    fi \
    # Run the package installation and setup
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -L https://github.com/prodrigestivill/go-cron/releases/download/$GOCRONVER/go-cron-$TARGETOS-$TARGETARCH.gz | zcat > /usr/local/bin/go-cron \
    && chmod a+x /usr/local/bin/go-cron \
    && apt-get purge -y --auto-remove ca-certificates \
    && apt-get clean

# Environment variables
ENV POSTGRES_DB="**None**" \
    POSTGRES_DB_FILE="**None**" \
    POSTGRES_HOST="**None**" \
    POSTGRES_PORT=5432 \
    POSTGRES_USER="**None**" \
    POSTGRES_USER_FILE="**None**" \
    POSTGRES_PASSWORD="**None**" \
    POSTGRES_PASSWORD_FILE="**None**" \
    POSTGRES_PASSFILE_STORE="**None**" \
    POSTGRES_EXTRA_OPTS="-Z6" \
    POSTGRES_CLUSTER="FALSE" \
    SCHEDULE="@daily" \
    BACKUP_DIR="/backups" \
    BACKUP_SUFFIX=".sql.gz" \
    BACKUP_KEEP_DAYS=7 \
    BACKUP_KEEP_WEEKS=4 \
    BACKUP_KEEP_MONTHS=6 \
    BACKUP_KEEP_N_DAILY="**None**" \
    BACKUP_KEEP_N_WEEKLY="**None**" \
    BACKUP_KEEP_N_MONTHLY="**None**" \
    HEALTHCHECK_PORT=8080

# Copy backup script
COPY backup.sh /backup.sh
RUN sed -i 's/\r$//' /backup.sh && chmod +x /backup.sh

# Define volume for backups
VOLUME /backups

# Entrypoint and command
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["exec /usr/local/bin/go-cron -s \"$SCHEDULE\" -p \"$HEALTHCHECK_PORT\" -- /backup.sh"]

# Healthcheck
HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f "http://localhost:$HEALTHCHECK_PORT/" || exit 1