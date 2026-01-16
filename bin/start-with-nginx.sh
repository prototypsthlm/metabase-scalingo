#!/usr/bin/env bash

set -e

echo "-----> Environment: PORT=$PORT, METABASE_PORT=$METABASE_PORT"

echo "-----> Starting Metabase on port 3000..."
HEROKU=true ./bin/start &

# Save Metabase PID
METABASE_PID=$!
echo "-----> Metabase PID: $METABASE_PID"

# Check if Metabase process is still running
sleep 2
if ! kill -0 $METABASE_PID 2>/dev/null; then
  echo "-----> ERROR: Metabase process died immediately after starting"
  exit 1
fi

# Wait for Metabase to be ready
echo "-----> Waiting for Metabase to start (checking port 3000)..."
for i in {1..60}; do
  if curl -s http://127.0.0.1:3000 > /dev/null 2>&1; then
    echo "-----> Metabase is ready!"
    break
  fi
  if [ $i -eq 60 ]; then
    echo "-----> ERROR: Metabase failed to start within 60 seconds"
    exit 1
  fi
  echo "       Waiting... ($i/60)"
  sleep 1
done

echo "-----> Starting Nginx on port $PORT..."
# Start nginx in foreground (this keeps the dyno alive)
exec bin/run
