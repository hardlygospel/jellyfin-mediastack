#!/bin/bash
# Resets any local script changes and pulls latest from GitHub
git checkout -- . && git pull && bash fix_download_client.sh
