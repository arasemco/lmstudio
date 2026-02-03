# syntax=docker/dockerfile:1.6

############################
# GLOBAL ARGUMENTS
############################
ARG DEBIAN_VERSION=bookworm-slim
ARG USERNAME=lms
ARG UID=1000
ARG GID=1000

############################
# BASE RUNTIME (CPU)
############################
FROM debian:${DEBIAN_VERSION} AS base

LABEL org.opencontainers.image.title="llmster"
LABEL org.opencontainers.image.description="LM Studio llmster headless container"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        procps \
        libgomp1 \
    && rm -rf /var/lib/apt/lists/*

############################
# USER SETUP
############################
ARG USERNAME
ARG UID
ARG GID

ENV USERNAME=${USERNAME}
ENV HOME=/home/${USERNAME}
ENV PATH=${HOME}/.local/bin:${HOME}/.lmstudio/bin:${PATH}

RUN groupadd -g ${GID} ${USERNAME} && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME}

USER ${USERNAME}
WORKDIR ${HOME}

############################
# INSTALL LMSTUDIO
############################
RUN curl -fsSL https://lmstudio.ai/install.sh -o /tmp/lmstudio-install.sh && \
    bash /tmp/lmstudio-install.sh

############################
# COMMON RUNTIME
############################
COPY --chown=${USERNAME}:${USERNAME} start.sh ${HOME}/.local/bin/start.sh
RUN chmod +x ${HOME}/.local/bin/start.sh

EXPOSE 1234

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD curl -sf http://127.0.0.1:1234/v1/models || exit 1

CMD ["start.sh"]


############################
# CPU
############################
FROM base AS cpu


############################
# VULKAN
############################
FROM base AS vulkan
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
        libvulkan1 \
        vulkan-tools \
    && rm -rf /var/lib/apt/lists/*

USER ${USERNAME}
