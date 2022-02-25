FROM alpine:latest
RUN apk --update add ca-certificates \
                     mailcap \
                     curl

HEALTHCHECK --start-period=2s --interval=5s --timeout=3s \
  CMD curl -f http://localhost/health || exit 1

VOLUME /srv
EXPOSE 80

RUN curl -L https://github.com/filebrowser/filebrowser/releases/download/v2.20.1/linux-amd64-filebrowser.tar.gz | tar -xvz -C /
RUN chmod +x /filebrowser

COPY settings.yaml /settings.yaml
COPY users.yaml /users.yaml
COPY start-filebrowser.sh /start-filebrowser.sh

RUN /filebrowser config import /settings.yaml
RUN /filebrowser users import /users.yaml

ENTRYPOINT [ "/start-filebrowser.sh" ]
