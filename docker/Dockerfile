FROM alpine:3.17
ENV APP_ENV=${APP_ENV:-dev}
ENV APP_DEBUG=${APP_DEBUG:-1}
ENV APP_USER=${APP_USER:-"satisfy"}
ENV APP_ROOT=${APP_ROOT:-'/usr/src/app'}
ENV SATISFY_VERSION=${SATISFY_VERSION:-"3.5.1"}
RUN apk add --update --no-cache \
        php81 \
        php81-fpm \
        php81-opcache \
        php81-pecl-apcu \
        php81-mysqli \
        php81-pgsql \
        php81-json \
        php81-openssl \
        php81-curl \
        php81-zlib \
        php81-soap \
        php81-xml \
        php81-fileinfo \
        php81-phar \
        php81-intl \
        php81-dom \
        php81-xmlreader \
        php81-ctype \
        php81-session \
        php81-iconv \
        php81-tokenizer \
        php81-zip \
        php81-simplexml \
        php81-mbstring \
        php81-gd \
        bash \
        nginx \
        runit \
        curl \
        wget \
        git \
        zip \
        unzip \
        openssh \
        lockfile-progs \
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache $runDeps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
    && rm -rf /var/cache/apk/* \
    && rm /etc/nginx/http.d/default.conf \
    && chown -R nobody.nobody /run \
    && chown -R nobody.nobody /var/lib/nginx \
    && chown -R nobody.nobody /var/log/nginx \
    && mkdir -p ${APP_ROOT}
COPY config/php.ini /etc/php81/conf.d/100-satisfy.ini
COPY --chmod=0755 config/lockfile /usr/bin/lockfile
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY --chmod=0755 entry.sh /entry.sh
RUN addgroup -S ${APP_USER} && \
    adduser -h /home/${APP_USER} -S ${APP_USER} -G ${APP_USER} && \
    chmod -R 0755 ${APP_ROOT} && \
    chown -R ${APP_USER}:${APP_USER} ${APP_ROOT} /var/lib/nginx /var/log/nginx /etc/nginx && \
    ln -sf /dev/stderr /var/log/php81/error.log && \
    wget -O /usr/local/bin/composer https://getcomposer.org/download/latest-stable/composer.phar && \
    chmod +x /usr/local/bin/composer
EXPOSE 8080/tcp
WORKDIR ${APP_ROOT}
RUN \
    yes | composer create-project --no-dev playbloom/satisfy . ${SATISFY_VERSION} && \
    rm ${APP_ROOT}/config/parameters.yml && \
    echo "HTTP server is up" > ${APP_ROOT}/web/serverup.txt && \
    chown -R ${APP_USER}:${APP_USER} ${APP_ROOT}
COPY --chmod=0755 --chown=${APP_USER}:${APP_USER} config/sync_repos.sh ${APP_ROOT}/sync_repos.sh
USER ${APP_USER}
RUN mkdir -p ~/.ssh && chmod 0700 ~/.ssh && ssh-keyscan \
    -H github.com gitlab.com bitbucket.org >> ~/.ssh/known_hosts && \
    mkdir -p ~/.composer && chown ${APP_USER}:${APP_USER} ~/.composer
ENTRYPOINT ["/entry.sh"]
