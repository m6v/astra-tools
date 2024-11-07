#!/usr/bin/env bash

VERSION=1.02

dir="/"

usage() {
  echo "Использование: $(basename $0) [-h|-v] [КАТАЛОГ]..."
  echo "Выводит права доступа к файлам и каталогам, находящимся в указанном каталоге,"
  echo "если каталог не задан, то начиная с корневого каталога"
  echo
  echo "  -h, --help    показать эту справку и выйти"
  echo "  -v. --version показать информацию о версии и выйти"
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      exit
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

# Присвоить переменной NAME имя дистрибутива
eval $(grep ^NAME /etc/os-release)
if [ "$NAME" == "Astra Linux" ]; then
  cmd="find $dir \! -type l -exec pdp-ls -daM --time-style=+ {} \; | cut -d' ' -f1,4-"
else
  cmd="find $dir \! -type l -exec ls -dal --time-style=+ {} \; | cut -d' ' -f1,3,4,7-"
fi

eval $cmd
