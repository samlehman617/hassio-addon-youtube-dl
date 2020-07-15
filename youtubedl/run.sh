#!/usr/bin/env bashio

# Save current directory so we can return later.
currdir=$(pwd)
bashio::log.info "Running from ${currdir}..."

# --- HANDLE CONFIGURATION -------------------------------------
change_config() {
    bashio::log.info "Building config..."

    # App configurations
    TEMP_CONFIG=$(mktemp)
    CONFIG="./data/config.json"

    # Get URL config
    URL=$(bashio::config 'url' )
    bashio::log.info "URL: ${URL}"
    if [[ "${URL:0:4}" == "http" ]] ; then
        URL=$(echo ${URL} | cut -d '/' -f3)
    fi
    bashio::log.info "URL: ${URL}"

    # Get SSL config
    USE_SSL=$(bashio::config.true 'ssl')
    CERTFILE=$(bashio::config 'certfile')
    KEYFILE=$(bashio::config 'keyfile')
    [[ $USE_SSL ]] && proto="https:\/\/" || proto="http:\/\/"

    # Get API config
    USE_API_KEY=$(bashio::config.true 'api.use_api')
    API_KEY=$(bashio::config 'api.api_key')
    USE_YOUTUBE_API=$(bashio::config.true 'api.use_youtube_api')
    YOUTUBE_API_KEY=$(bashio::config 'api.youtube_api_key')

    bashio::log.info "Using $proto..."
    bashio::log.info "Url: $URL"
    bashio::log.info "Cert: $CERTFILE"
    bashio::log.info "Key: $KEYFILE"

    bashio::log.info "Use API key?...$USE_API_KEY"
    bashio::log.info "API Key: $API_KEY"
    bashio::log.info "Use YouTube API?...$USE_YOUTUBE_API"
    bashio::log.info "YouTube API Key: $YOUTUBE_API_KEY"

    # Set 'url'
    # [[ $USE_SSL ]] && proto="https://" || proto="http://"
    url_sel=".YoutubeDLMaterial.Host.url = \"${proto}${URL}\""
    [[ ! -z ${URL} ]] && \
        jq "${url_sel}" $CONFIG > $TEMP_CONFIG


    # Set 'use-encryption'
    ssl_sel=".YoutubeDLMaterial.Encryption.\"use-encryption\" ="
    [[ $USE_SSL ]] && \
        jq "${ssl_sel} true" $TEMP_CONFIG >> $TEMP_CONFIG || \
        jq "${ssl_sel} false" $TEMP_CONFIG >> $TEMP_CONFIG

    # Set 'cert-file-path'
    cert_sel=".YoutubeDLMaterial.Encryption.\"cert-file-path\" = \"${CERTFILE}\""
    [[ -f "/ssl/${CERTFILE}" ]] && \
        jq "${cert_sel}" $TEMP_CONFIG >> $TEMP_CONFIG

    # Set 'key-file-path'
    key_sel=".YoutubeDLMaterial.Encryption.\"key-file-path\" = \"${KEYFILE}\""
    [[ -f "/ssl/${KEYFILE}" ]] && \
        jq "${key_sel}" $TEMP_CONFIG >> $TEMP_CONFIG

    # Set 'use_API_key'
    apikey_sel=".YoutubeDLMaterial.API.use_API_key ="
    [[ $USE_API_KEY ]] && \
        jq "${apikey_sel} true" $TEMP_CONFIG >> $TEMP_CONFIG || \
        jq "${apikey_sel} false" $TEMP_CONFIG >> $TEMP_CONFIG

    # Set 'API_key'
    [[ -z $API_KEY ]] && \
        jq ".YoutubeDLMaterial.API.API_key = ${API_KEY}" $TEMP_CONFIG >> $TEMP_CONFIG

    # Set 'use_youtube_API'
    yt_apikey_sel=".YoutubeDLMaterial.API.use_youtube_API ="
    [[ $USE_YOUTUBE_API ]] && \
        jq "${yt_apikey_sel} true" $TEMP_CONFIG >>$TEMP_CONFIG || \
        jq "${yt_apikey_sel} false" $TEMP_CONFIG >> $TEMP_CONFIG

    # Set 'youtube_API_key'
    [[ -z $YOUTUBE_API_KEY ]] && \
        jq ".YoutubeDLMaterial.API.youtube_API_key = ${YOUTUBE_API_KEY}" $TEMP_CONFIG >> $TEMP_CONFIG

    # Save new config.
    cat $TEMP_CONFIG > /app/appdata/default.json
    cat $TEMP_CONFIG > /app/appdata/encrypted.json
    bashio::log.info "Config generated."
    bashio::log.info "$(cat $TEMP_CONFIG)"
    rm $TEMP_CONFIG
}
change_config
bashio::log.info "Running webapp..."
# TODO?: Handle config saved to /config
# --------------------------------------------------------------


# --- RUN WEBSERVER --------------------------------------------

# Run YouTube-DL node.js app
CMD="node app.js"

# if the first arg starts with "-" pass it to program
if [ "${1#-}" != "$1" ]; then
  set -- "$CMD" "$@"
fi

# chown current working directory to current user
if [ "$*" = "$CMD" ] && [ "$(id -u)" = "0" ]; then
  find . \! -user "$UID" -exec chown "$UID:$GID" -R '{}' +
  exec su-exec "$UID:$GID" "$0" "$@"
fi

exec "$@"