#!/usr/bin/env bash

VERSION=1.01

NC='\033[0m' # No Color
Red='\033[0;31m' # Red
Green='\033[0;32m' # Green

checks=0
errors=0

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help=true
      ;;
    -v|--verbose)
      verbose=true
      ;;      
    --version)
      echo $(basename $0) $VERSION
      exit
      ;;
    *)
      file=$1
      if [ ! -f $file ]; then
        echo "Файл $file не существует"
        exit
      fi
      ;;
  esac
  shift
done

if [ -n "$show_help" ]; then
  echo "Использование: chkperms [-h|-v] ФАЙЛ..."
  echo "Проверяет соответствие прав доступа к файлам и каталогам матрице доступа"
  echo
  echo "  -h, --help    показать эту справку и выйти"
  echo "  -v, --verbose показывать успешные проверки"
  echo "  --version     показать информацию о версии и выйти"
  echo "  ФАЙЛ          файл с матрицей даступа"
  exit
fi

if [ -z "$file" ]; then
  echo "Ошибка: файл с матрицей доступа не задан" >&2
  exit
fi

echo "Проверка прав доступа:"
while read -r line; do
    ((checks++))
    # Получить имя файла, обрамленное одинарными кавычками на случай наличия в нем пробелов
    fname="'"$(echo $line  | cut -d' ' -f4-)"'"
    perms=$(eval "ls -dal --time-style=+ ${fname} | cut -d' ' -f1,3,4,7-")
    if [ "$line" = "$perms" ]; then
      if [ -n "$verbose" ]; then
        echo -e "${fname}...${Green}успешно${NC}"
      fi
    else
      ((errors++))
      echo -e "${fname}...${Red}ошибка${NC}"
    fi
done <$file 

echo "Проверено объектов "$checks", ошибок "$errors
