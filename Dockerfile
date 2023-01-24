ARG ALPINE_VERSION=edge
FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Björn Busse <bj.rn@baerlin.eu>"

ENV APK_ADD="bash curl postgresql-client" \
    USER="psql"

# Add packages
RUN apk update \
    && apk upgrade \
    && apk add --no-cache $APK_ADD \
    && addgroup -S $USER && adduser -S -G $USER $USER \
    && mkdir /import \
    && chown $USER /import

# Add SQL
COPY gtfs_psql.sql /import

# Add entrypoint
USER $USER
COPY import.sh /
ENTRYPOINT ["/import.sh"]
