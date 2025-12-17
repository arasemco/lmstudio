FROM ubuntu:22.04 AS lmstudio-builder

ARG LMSTUDIO_VERSION=0.3.35-1
RUN apt-get update && apt-get install -y curl

WORKDIR /build
RUN curl -L "https://installers.lmstudio.ai/linux/x64/${LMSTUDIO_VERSION}/LM-Studio-${LMSTUDIO_VERSION}-x64.AppImage" \
    -o lmstudio.AppImage && \
    chmod +x lmstudio.AppImage && \
    ./lmstudio.AppImage --appimage-extract && \
    chown -R 1000:1000 /build/squashfs-root


FROM debian:stable-slim

COPY --from=lmstudio-builder /build/squashfs-root /opt/lmstudio
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99
ENV PUID=1000
ENV PGID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    openbox \
    x11vnc \
    novnc websockify \
    openrc \
    dbus \
    dbus-x11 \
    libnspr4 \
    libnss3 \
    libgtk-3-0 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*  \
      /var/log/* \
      /tmp/*

RUN echo "DISPLAY=${DISPLAY}" >> /etc/environment \
    && echo 'rc_controller_cgroups=no' >> /etc/rc.conf \
    && echo 'rc_cgroup_mode=legacy' >> /etc/rc.conf

RUN for rl in sysinit boot default shutdown; do rc-update show "$rl" | awk '{print $1}' | xargs -r -I{} rc-update del {} "$rl"; done
COPY rc-services /etc/init.d
RUN chmod +x /etc/init.d/* \
    && rc-update add novnc default \
    && rc-update add lmstudio-headless default

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/sbin/openrc-init"]

# ports
EXPOSE 1234 5900 6080
WORKDIR /root
