#!/bin/sh
set -eu

CERT_DIR="/usr/local/apache2/conf/ssl_conf"
CERT_FILE="${CERT_DIR}/httpddomoticzserver.crt"
KEY_FILE="${CERT_DIR}/httpddomoticzserver.key"
META_FILE="${CERT_DIR}/server-name"
SERVER_NAME="${SERVER_NAME:-domatique.freeboxos.fr}"
CERT_VALIDITY_DAYS="${CERT_VALIDITY_DAYS:-3650}"

mkdir -p "${CERT_DIR}"

need_regen=0
if [ ! -f "${CERT_FILE}" ] || [ ! -f "${KEY_FILE}" ] || [ ! -f "${META_FILE}" ]; then
  need_regen=1
else
  stored_name=$(cat "${META_FILE}")
  if [ "${stored_name}" != "${SERVER_NAME}" ]; then
    need_regen=1
  fi
fi

if [ "${need_regen}" -eq 1 ]; then
  echo "[httpd-cert-init] generating TLS certificate for ${SERVER_NAME}" >&2
  umask 077
  openssl req -x509 -nodes -days "${CERT_VALIDITY_DAYS}" -newkey rsa:2048 \
    -keyout "${KEY_FILE}" \
    -out "${CERT_FILE}" \
    -subj "/CN=${SERVER_NAME}/O=Home/C=FR" \
    -addext "subjectAltName=DNS:${SERVER_NAME}"
  chmod 600 "${KEY_FILE}"
  chmod 644 "${CERT_FILE}"
  printf '%s\n' "${SERVER_NAME}" > "${META_FILE}"
else
  echo "[httpd-cert-init] reusing TLS certificate for ${SERVER_NAME}" >&2
fi

if [ "$#" -eq 0 ]; then
  set -- httpd-foreground
fi

exec "$@"
