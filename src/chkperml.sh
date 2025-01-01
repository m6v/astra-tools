#!/usr/bin/env bash

VERSION=1.02

# Используемые escape-последовательности
nc='\033[0m' # Нет цвета
red='\033[0;31m' # Красный
green='\033[0;32m' # Зеленый

checks=0
errors=0
verbose=''

while read line; do
  ((checks++))
  fname=$(echo $line  | cut -d' ' -f4-)
  if [ ! -e "${fname}" ]; then
    echo -e "${fname}...${red}нет такого файла или каталога${nc}"
    continue
  fi
  perms=$(eval "ls -dal --time-style=+ '${fname}' | cut -d' ' -f1,3,4,7-")
  if [ "$line" = "$perms" ]; then
    if [ -n "$verbose" ]; then
      echo -e "${fname}...${green}успешно${nc}"
    fi
  else
    ((errors++))
    echo -e "${fname}...${red}ошибка${nc}"
  fi  
done

echo "Проверено объектов "$checks", ошибок "$errors
