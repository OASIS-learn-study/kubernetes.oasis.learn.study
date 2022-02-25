#!/bin/sh
set -euxo pipefail

/filebrowser config set --baseurl=$CONTEXT_ROOT
/filebrowser

