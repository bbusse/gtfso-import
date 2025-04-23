# gtfso-import

Import gtfs data into PostgreSQL

## Use `import.sh` Directly
Make sure the required tools (`psql`, `curl`, `unzip`) are installed and the PostgreSQL host is accessible

### Example Usage
```
$ git clone https://github.com/bbusse/gtfso-import
$ cd gtfso-import
$ DB_HOST=fdc7:a61d:d247::42 \
  DB_USER=gtfso \
  DB_NAME=gtfso \
  DB_LOCALE=de_DE.UTF-8 \
  URL_DATA=https://www.vbb.de/vbbgtfs \
  bash import.sh
```

## Use Container
Make sure the PostgreSQL host is accessible from the container
```
$ podman run -e DB_HOST=fdc7:a61d:d247::42 \
             -e DB_USER=gtfso \
             -e DB_NAME=gtfso \
             -e DB_LOCALE=de_DE.UTF-8 \
             -e URL_DATA=https://www.vbb.de/vbbgtfs \
             ghcr.io/bbusse/gtfso-import:latest
```

## Build Container
```
$ git clone https://github.com/bbusse/gtfso-import
$ cd gtfso-import
$ podman build -t gtfso-import .
```

## Resources
https://en.wikipedia.org/wiki/GTFS  
https://developers.google.com/transit/gtfs/reference/extended-route-types  
[GTFS data for Berlin](https://www.vbb.de/vbbgtfs)  
[GTFS data for Munich](https://www.mvg.de/static/gtfs/gtfs-mvg.zip)