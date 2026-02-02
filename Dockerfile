########################################################################################################################
FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble AS lmstudio
LABEL maintainer="asemo"

# title
ENV TITLE="LM Studio" \
    NO_GAMEPAD=true

# Update
RUN apt-get update && apt-get upgrade -y

# set version & label
ARG LMSTUDIO_VERSION=0.3.35-1
LABEL lm-studio-version="${LMSTUDIO_VERSION}"

# Building
WORKDIR /build
RUN curl -L "https://installers.lmstudio.ai/linux/x64/${LMSTUDIO_VERSION}/LM-Studio-${LMSTUDIO_VERSION}-x64.AppImage" \
    -o lmstudio.AppImage && \
    chmod +x lmstudio.AppImage && \
    ./lmstudio.AppImage --appimage-extract && \
    mkdir -p /config/app && \
    mv /build/squashfs-root /config/app/lmstudio && \
    chown -R abc:abc /config/app

# Cleanup
RUN echo "**** cleanup ****" && \
    apt-get auto-remove && \
    apt-get autoclean && \
    rm -rf  \
      /build \
      /config/.cache \
      /config/.launchpadlib \
      /var/lib/apt/lists/* \
      /var/tmp/* \
      /tmp/*

# Customizing
RUN cp /config/app/lmstudio/lm-studio.png /usr/share/selkies/www/icon.png
RUN mkdir -p /defaults \ && printf '%s\n#!/bin/bash\n\necho "launching by s6 service manager"' > /defaults/autostart

# s6 service gui app
RUN mkdir -p /etc/services.d/lmstudio
RUN cat > /etc/services.d/lmstudio/run <<'EOF'
#!/bin/bash

export USER=abc
export HOME=/config
export DISPLAY=:1
export XAUTHORITY=/config/.Xauthority

while [ ! -S /tmp/.X11-unix/X1 ]
do sleep 0.5
done

chown -R abc:abc /config/app
exec s6-setuidgid abc /config/app/lmstudio/lm-studio --no-sandbox %U
EOF
RUN chmod +x /etc/services.d/lmstudio/run

# s6 service headless serving
RUN mkdir -p /etc/services.d/lms
RUN cat > /etc/services.d/lms/run <<'EOF'
#!/bin/bash

export USER=abc
export HOME=/config

while [ ! -S /tmp/.X11-unix/X1 ]
do sleep 0.5
done

while [ ! -x /config/.lmstudio/bin/lms ]
do sleep 1
done

sleep 5
s6-setuidgid abc /config/.lmstudio/bin/lms daemon up
s6-setuidgid abc /config/.lmstudio/bin/lms server start

#s6-setuidgid abc /config/.lmstudio/bin/lms get openai/gpt-oss-20b --yes
s6-setuidgid abc /config/.lmstudio/bin/lms get nomic-embed-text-v1.5-GGUF@Q8_0 --yes
s6-setuidgid abc /config/.lmstudio/bin/lms load nomic-ai/nomic-embed-text-v1.5-GGUF/nomic-embed-text-v1.5.Q8_0.gguf --identifier text-embedding-nomic-embed-text-v1.5@q8_0

exec s6-setuidgid abc /config/.lmstudio/bin/lms log stream
EOF
RUN chmod +x /etc/services.d/lms/run

# ports and volumes
#      API  WebUI
EXPOSE 1234 3000
WORKDIR /config


########################################################################################################################
FROM debian:bookworm-slim AS llmster

# system deps required by lmstudio/llmster headless mode
RUN apt-get update && \
    apt-get install -y curl ca-certificates libgomp1 libvulkan1 vulkan-tools && \
    rm -rf /var/lib/apt/lists/*

# create non-root user
RUN useradd -m -s /bin/bash lmstudio
USER lmstudio
WORKDIR /home/lmstudio

# install lmstudio as non-root
RUN curl -fsSL https://lmstudio.ai/install.sh | bash

# installer places binaries in ~/.local/bin
ENV PATH="/home/lmstudio/.local/bin:${PATH}"
ENV PATH="/home/lmstudio/.lmstudio/bin:${PATH}"

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD curl -sf http://127.0.0.1:1234/v1/models || exit 1

RUN cat > /home/lmstudio/start.sh <<'EOF'
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
  sleep 16
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
EOF
RUN chmod +x /home/lmstudio/start.sh

#      API
EXPOSE 1234
CMD ["/home/lmstudio/start.sh"]
