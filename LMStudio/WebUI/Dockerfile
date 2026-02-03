# syntax=docker/dockerfile:1.6
ARG LMSTUDIO_VERSION=0.3.35-1

############################
# STAGE 0 — BUILD LM STUDIO
############################
FROM ubuntu:24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG LMSTUDIO_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN curl -L "https://installers.lmstudio.ai/linux/x64/${LMSTUDIO_VERSION}/LM-Studio-${LMSTUDIO_VERSION}-x64.AppImage" \
      -o lmstudio.AppImage \
 && chmod +x lmstudio.AppImage \
 && ./lmstudio.AppImage --appimage-extract \
 && mv squashfs-root lmstudio


############################
# STAGE 1 — RUNTIME
############################
FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble

ARG LMSTUDIO_VERSION
LABEL lm-studio-version="${LMSTUDIO_VERSION}"

ENV TITLE="LM Studio" \
    NO_GAMEPAD=true \
    PATH=${HOME}/.lmstudio/bin:${PATH}

COPY --from=builder --chown=abc:abc /build/lmstudio /config/app/lmstudio
COPY services/s6-overlay /etc/services.d
COPY defaults/autostart /defaults/autostart

RUN chmod +x /etc/services.d/*/run \
 && cp /config/app/lmstudio/lm-studio.png /usr/share/selkies/www/icon.png

EXPOSE 1234 3000
WORKDIR /config
