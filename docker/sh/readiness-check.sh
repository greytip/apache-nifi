#!/bin/bash -e

if [ "$NIFI_HTTPS_PORT" == "8443" ]; then
    curl -kv \
      --cert ${NIFI_BASE_DIR}/data/cert/admin/crt.pem --cert-type PEM \
      --key ${NIFI_BASE_DIR}/data/cert/admin/key.pem --key-type PEM \
      https://$(hostname -f):$NIFI_HTTPS_PORT/nifi-api/controller/cluster > $NIFI_BASE_DIR/data/cluster.state
else
    curl -kv \
      http://$(hostname -f):$NIFI_HTTP_PORT/nifi-api/controller/cluster > $NIFI_BASE_DIR/data/cluster.state
fi

STATUS=$(cat $NIFI_BASE_DIR/data/cluster.state | jq -r ".cluster.nodes[] | select(.status != \"DISCONNECTED\") | select(.address==\"$(hostname -f)\") | .status")

if [[ ! $STATUS = "CONNECTED" ]]; then
  echo "Node not found with CONNECTED state. Full cluster state:"
  jq . $NIFI_BASE_DIR/data/cluster.state
  exit 1
fi
