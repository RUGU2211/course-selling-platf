#!/bin/bash
set -e

# Update Jenkins config.xml to use port 8090 if it exists
if [ -f /var/jenkins_home/config.xml ]; then
  echo "Updating Jenkins config to use port 8090..."
  sed -i 's/<port>8080<\/port>/<port>8090<\/port>/g' /var/jenkins_home/config.xml 2>/dev/null || true
fi

# Set Jenkins port via environment variable
export JENKINS_HTTP_PORT=${JENKINS_HTTP_PORT:-8090}
export JAVA_OPTS="${JAVA_OPTS} -DhttpPort=${JENKINS_HTTP_PORT}"

echo "Jenkins will start on port ${JENKINS_HTTP_PORT}"

# Run original Jenkins entrypoint
exec /usr/bin/tini -- /usr/local/bin/jenkins.sh "$@"

