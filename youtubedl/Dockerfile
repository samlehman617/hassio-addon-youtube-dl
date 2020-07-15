ARG BUILD_FROM=hassioaddons/base:latest
FROM ${BUILD_FROM}

# Copy root filesystem
# COPY rootfs /

ARG ALLOW_CONFIG_MUTATIONS=true
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Add labels to our container
LABEL \
  io.hass.name="YouTube DL" \
  io.hass.description="Material design frontend for youtube-dl. Download YouTube videos." \
  io.hass.arch="${BUILD_ARCH}" \
  io.hass.type="addon" \
  io.hass.version=${BUILD_VERSION} \
  maintainer="Sam Lehman <samlehman617@gmail.com>" \
  org.opencontainers.image.title="YouTube DL" \
  org.opencontainers.image.description="Material design frontend for youtube-dl. Download YouTube videos." \
  org.opencontainers.image.vendor="Sam Lehman's Hassio Addons" \
  org.opencontainers.image.authors="Sam Lehman <samlehman617@gmail.com" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.url="https://hub.docker.com/r/samlehman617/hassio-addon-youtube-dl" \
  org.opencontainers.image.source="https://github.com/samlehman617/hassio-addon-youtube-dl" \
  org.opencontainers.image.documentation="https://github.com/samlehman617/hassio-addon-youtube-dl/blob/master/README.md" \
  org.opencontainers.image.created=${BUILD_DATE} \
  org.opencontainers.image.revision=${BUILD_REF} \
  org.opencontainers.image.version=${BUILD_VERSION}

# Configure group/user
ENV UID=1000 \
    GID=1000 \
    USER=youtube
RUN addgroup -S $USER -g $GID && adduser -D -S $USER -G $USER -u $UID

# Setup base
RUN apk add --no-cache \
  bash \
  coreutils \
  wget \
  git \
  curl-dev

# Add necessary packages
RUN apk add --no-cache \
    ffmpeg \
    npm \
    python2 \
    su-exec  \
  && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
    atomicparsley

# Clone the repository into /app
RUN \
  echo "Cloning repo..." && \
  git clone https://github.com/Tzahi12345/YoutubeDL-Material /gitrepo && \
  echo "Cloned repo."

RUN \
  npm install -g package-json-merge && \
  package-json-merge /gitrepo/package.json /gitrepo/backend/package.json > /gitrepo/combined_package.json && \
  rm /gitrepo/backend/package.json /gitrepo/package.json && \
  cp -r /gitrepo/backend /app && \
  cp /gitrepo/combined_package.json /app/package.json

# mkdir -p /gitrepo && \
# rm /app/backend/Dockerfile /app/backend/entrypoint.sh && \
# cd /app && \

# Use /app
# WORKDIR /app

# Copy the node deps into working dir.
# COPY --chown=$UID:$GID [ "package.json", "package-lock.json", "/app/" ]

# Install NPM dependencies
RUN \
  echo "Installing node modules..." && \
  npm install && chown -R $UID:$GID ./ && \
  echo "Installed node modules."

# COPY --chown=$UID:$GID [ "./", "/app/" ]
# Copy the backend into working dir.
# COPY --chown=$UID:$GID [ "./backend", '/app/' ]

# Make directories for accessing data
# RUN \
#  mkdir -p /share/video/YouTube && \
#  mkdir -p /share/audio/YouTube && \
RUN \
  echo "Making directories..." && \
  ls . && \
  mkdir -p /share/YouTubeDL/{appdata,audio,authentication,public,subscriptions,users,video} && \
  echo "Created dirs."

# Symlink media/data dirs to Hassio dirs.
RUN \
  echo "Symlinking dirs..." && \
  ln -s /app/public         /share/YouTubeDL/public         && \
  ln -s /app/subscriptions  /share/YouTubeDL/subscriptions  && \
  ln -s /app/authentication /share/YouTubeDL/authentication && \
  ln -s /app/audio          /share/YouTubeDL/audio          && \
  ln -s /app/video          /share/YouTubeDL/video          && \
  echo "Symlinked dirs."


# Expose port
EXPOSE 17442

RUN echo "Running app..."

# Move scripts into root.
COPY run.sh /
COPY config.json /
COPY default.conf /
RUN chmod a+x /run.sh
ENTRYPOINT [ "/run.sh" ]