#!/bin/sh

/etc/rds_exporter/generate_rds_list.py

exec "$@"
