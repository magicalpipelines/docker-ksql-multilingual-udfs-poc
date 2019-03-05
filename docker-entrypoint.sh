#!/bin/env bash

# Create the KSQL server configuration file
if [ -z "$QUERIES_FILE" ]; then
# No query file was specified, so run KSQL in interactive mode
cat <<EOF >/etc/ksql-server.properties
bootstrap.servers=$BOOTSTRAP_SERVERS
listeners=http://localhost:8088
EOF
else
# A query file was specified, so run KSQL in headless mode
cat <<EOF >/etc/ksql-server.properties
bootstrap.servers=$BOOTSTRAP_SERVERS
ksql.queries.file=$QUERIES_FILE
EOF
fi

cat /etc/ksql-server.properties

KSQL_PID=0

handleInterrupt() {
  kill "$KSQL_PID"
  wait "$KSQL_PID"
  exit
}

trap "handleInterrupt" SIGHUP SIGINT SIGTERM
"$@" &
KSQL_PID=$!
wait

"$@"
