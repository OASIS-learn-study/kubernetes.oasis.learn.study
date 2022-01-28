# Filebrowser

This is https://filebrowser.org, from https://github.com/filebrowser/filebrowser.

    podman build -f filebrowser/Dockerfile -t filebrowser ./filebrowser

To run without [the YAML](../vanilla.yaml), where it's normally used, just to test:

    podman run -it --rm -p 8080:80 filebrowser
