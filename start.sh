#!/bin/bash

copyparty -c /app/copyparty.conf &

cloudflared tunnel run --token "$COPYPARTY_CLOUDFLARED_TOKEN"
