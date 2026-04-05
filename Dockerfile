# syntax=docker/dockerfile:1.7

FROM alpine:3.23 AS fetcher

ARG UPSTREAM_TAG
ARG DIST_ASSET=dist-no-fonts.zip
ARG DIST_URL

RUN apk add --no-cache ca-certificates curl unzip

RUN set -eux; \
    test -n "${UPSTREAM_TAG}"; \
    test -n "${DIST_URL}"; \
    echo "Downloading ${DIST_ASSET} for ${UPSTREAM_TAG}"; \
    mkdir -p /work /web; \
    curl -fL --retry 5 --retry-delay 2 --retry-all-errors "${DIST_URL}" -o /work/dist.zip; \
    unzip -q /work/dist.zip -d /work/unpacked; \
    if [ -d /work/unpacked/dist ]; then \
      cp -a /work/unpacked/dist/. /web/; \
    else \
      cp -a /work/unpacked/. /web/; \
    fi; \
    test -f /web/index.html

FROM caddy:2-builder AS caddy-builder

RUN CGO_ENABLED=0 xcaddy build --output /out/caddy

FROM alpine:3.23 AS runtime-dirs

RUN mkdir -p /out/tmp && chmod 1777 /out/tmp

FROM scratch

COPY --from=caddy-builder /out/caddy /usr/bin/caddy
COPY --from=fetcher /web/ /srv/
COPY --from=runtime-dirs /out/tmp /tmp
COPY Caddyfile /etc/caddy/Caddyfile

ENV HOME=/tmp
ENV XDG_CONFIG_HOME=/tmp
ENV XDG_DATA_HOME=/tmp
ENV PORT=8080

USER 65532:65532
EXPOSE 8080

ENTRYPOINT ["/usr/bin/caddy"]
CMD ["run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
