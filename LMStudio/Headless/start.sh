#!/usr/bin/env bash
set -e

echo "[lmstudio] starting daemon"
lms daemon up

echo "[lmstudio] starting server on :1234"
lms server start --bind 0.0.0.0 --port 1234

echo "[lmstudio] checking embedding model availability"
#if ! lms ls --embedding | grep -q 'text-embedding-nomic-embed-text-v1.5@q8_0'
if ! ls /home/lmstudio/.lmstudio/models/nomic-ai/nomic-embed-text-v1.5-GGUF/nomic-embed-text-v1.5.Q8_0.gguf 1>/dev/null 2>&1
then
    echo "[lmstudio] embedding model not found, waiting for registry bootstrap"
    sleep 24
    echo "[lmstudio] downloading embedding model"
    lms get --yes "nomic-ai nomic-embed-text-v1.5-GGUF@Q8_0"
else
    echo "[lmstudio] embedding model already present"
fi

echo "[lmstudio] loading embedding model"
lms load nomic-ai/nomic-embed-text-v1.5-GGUF/nomic-embed-text-v1.5.Q8_0.gguf \
  --identifier text-embedding-nomic-embed-text-v1.5@q8_0

echo "[lmstudio] initialization complete, streaming logs"
exec lms log stream
