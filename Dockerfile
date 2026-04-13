# syntax=docker/dockerfile:1

### ── Stage 1: build static PHP ────────────────────────────────────────────────
FROM alpine:edge AS spc-builder

RUN apk add --no-cache \
        autoconf \
        automake \
        bash \
        binutils \
        bison \
        build-base \
        cmake \
        curl \
        file \
        flex \
        git \
        jq \
        libtool \
        linux-headers \
        m4 \
        pkgconfig \
        re2c \
        upx \
        wget \
        xz \
        php composer php-tokenizer php-dom php-simplexml \
        unzip

WORKDIR /static-php-cli
ADD https://github.com/crazywhalecc/static-php-cli/archive/refs/heads/main.zip /tmp/spc.zip
RUN unzip /tmp/spc.zip -d /tmp \
    && cp -a /tmp/static-php-cli-main/. . \
    && rm -rf /tmp/spc.zip /tmp/static-php-cli-main
RUN composer install --no-dev --no-scripts --no-interaction --optimize-autoloader

ENV PATH="/static-php-cli/bin:$PATH"

ADD craft.yml craft.yml
RUN spc install-pkg upx

# Set env to reduce mem usage during build
# Mainly because sqlite requires a lot of memory to build, and tent to run in to OOM error
ENV SPC_CONCURRENCY=4
ENV SPC_DEFAULT_C_FLAGS="-fPIC -O1"
ENV SPC_DEFAULT_CXX_FLAGS="-fPIC -O1"
RUN --mount=type=cache,target=/static-php-cli/downloads/ \
    spc craft --verbose

ENV PATH="/static-php-cli/buildroot/bin:$PATH"

### ── Stage 2: download KaraDAV source ──────────────────────────────────────────
FROM alpine AS source

RUN apk add --no-cache unzip
ADD https://github.com/kd2org/karadav/archive/refs/heads/main.zip /tmp/app.zip
RUN unzip /tmp/app.zip -d /tmp \
    && mv /tmp/karadav-main /app \
    && rm -rf /app/.github /app/tests /app/doc* /app/*.md /app/*.txt

FROM alpine AS final-deps
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /tmp
WORKDIR /var/tmp

FROM scratch AS final

COPY --from=final-deps /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=final-deps /etc/passwd /etc/passwd
COPY --from=final-deps /etc/group  /etc/group
COPY --from=final-deps /tmp  /tmp
COPY --from=final-deps /var/tmp /var/tmp

COPY --from=ghcr.io/tarampampam/microcheck:1 /bin/httpcheck /bin/httpcheck
COPY --from=spc-builder /static-php-cli/buildroot/bin/php /usr/local/bin/php
COPY --from=source /app /app

WORKDIR /app
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/app/www", "/app/www/_router.php"]

EXPOSE 8080

HEALTHCHECK --interval=10s --start-period=5s --start-interval=1s \
    CMD ["/bin/httpcheck", "http://127.0.0.1:8080/status.php"]
