FROM alpine:latest
RUN apk --update add ca-certificates \
                     mailcap \
                     curl

HEALTHCHECK --start-period=2s --interval=5s --timeout=3s \
  CMD curl -f http://localhost/health || exit 1

VOLUME /srv
EXPOSE 80

COPY filebrowser.db /filebrowser.db
ADD https://github.com/filebrowser/filebrowser/releases/download/v2.20.1/linux-amd64-filebrowser.tar.gz /filebrowser

ENTRYPOINT [ "/filebrowser" ]
