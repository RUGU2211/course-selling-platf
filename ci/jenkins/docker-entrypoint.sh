#!/bin/bash
set -e

# Set Jenkins port via environment variable first
export JENKINS_HTTP_PORT=${JENKINS_HTTP_PORT:-8090}
export JAVA_OPTS="${JAVA_OPTS} -DhttpPort=${JENKINS_HTTP_PORT}"

# Update Jenkins config.xml to use port 8090 if it exists
if [ -f /var/jenkins_home/config.xml ]; then
  echo "Updating Jenkins config.xml to use port ${JENKINS_HTTP_PORT}..."
  # Use a more robust sed pattern to match any port number
  sed -i "s/<port>[0-9]*<\/port>/<port>${JENKINS_HTTP_PORT}<\/port>/g" /var/jenkins_home/config.xml 2>/dev/null || true
  # Also try to add it if it doesn't exist
  if ! grep -q "<port>${JENKINS_HTTP_PORT}</port>" /var/jenkins_home/config.xml 2>/dev/null; then
    # Try to find the httpPort section and update it
    sed -i "s/<httpPort>[0-9]*<\/httpPort>/<httpPort>${JENKINS_HTTP_PORT}<\/httpPort>/g" /var/jenkins_home/config.xml 2>/dev/null || true
  fi
fi

echo "Jenkins will start on port ${JENKINS_HTTP_PORT}"

# Run original Jenkins entrypoint
exec /usr/bin/tini -- /usr/local/bin/jenkins.sh "$@"

