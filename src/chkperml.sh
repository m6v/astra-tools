#!/usr/bin/env bash

VERSION=1.02

NC='\033[0m' # No Color
Red='\033[0;31m' # Red
Green='\033[0;32m' # Green

checks=0
errors=0
verbose=''

while read line; do
  ((checks++))
  fname=$(echo $line  | cut -d' ' -f4-)
  if [ ! -e "${fname}" ]; then
    echo -e "${fname}...${Red}нет такого файла или каталога${NC}"
    continue
  fi
  perms=$(eval "ls -dal --time-style=+ '${fname}' | cut -d' ' -f1,3,4,7-")
  if [ "$line" = "$perms" ]; then
    if [ -n "$verbose" ]; then
      echo -e "${fname}...${Green}успешно${NC}"
    fi
  else
    ((errors++))
    echo -e "${fname}...${Red}ошибка${NC}"
  fi  
done

echo "Проверено объектов "$checks", ошибок "$errors
