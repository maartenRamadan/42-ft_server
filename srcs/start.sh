#!/bin/bash

MYSQL_PWD='codam' mysqld &
service php7.3-fpm start
nginx -g "daemon off;"