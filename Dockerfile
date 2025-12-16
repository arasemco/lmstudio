FROM ubuntu:22.04 AS lmstudio-builder

ARG LMSTUDIO_VERSION=0.3.35-1
RUN apt-get update && apt-get install -y curl

WORKDIR /build
RUN curl -L "https://installers.lmstudio.ai/linux/x64/${LMSTUDIO_VERSION}/LM-Studio-${LMSTUDIO_VERSION}-x64.AppImage" \
    -o lmstudio.AppImage && \
    chmod +x lmstudio.AppImage && \
    ./lmstudio.AppImage --appimage-extract && \
    ls /build/squashfs-root


FROM ubuntu:22.04

COPY --from=lmstudio-builder /build/squashfs-root /opt/lmstudio
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0
ENV PUID=1000
ENV PGID=1000

RUN apt-get update && apt-get install -y \
    xvfb \
    openbox \
    x11vnc \
    novnc websockify \
    supervisor \
    dbus \
    dbus-x11 \
    xterm \
    libnspr4 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libxshmfence1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /run/dbus && \
    dbus-uuidgen --ensure

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n"]

# ports
EXPOSE 1234 5900 6080
