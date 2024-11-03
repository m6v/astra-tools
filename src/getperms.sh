#!/usr/bin/env bash

VERSION=1.01

dir="/"

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help=true
      ;;
    -v|--version)
      echo $(basename $0) $VERSION
      exit
      ;;
    *)
      dir=$1
      if [ ! -d $dir ]; then
        echo "Ошибка: каталог $dir не существует" >&2
        exit
      fi
      ;;
  esac
  shift
done

if [ -n "$show_help" ]; then
  echo "Использование: chkperms [-h|-v] [КАТАЛОГ]..."
  echo "Выводит права доступа к файлам и каталогам, находящимся в указанном каталоге,"
  echo "если каталог не задан, то начиная с корневого каталога"
  echo
  echo "  -h, --help    показать эту справку и выйти"
  echo "  -v. --version показать информацию о версии и выйти"
  exit
fi

# find $dir -type f -exec ls -dal --time-style=+ {} \; | cut -d' ' -f1,3,4,7-
find $dir -exec ls -dal --time-style=+ {} \; | cut -d' ' -f1,3,4,7-
