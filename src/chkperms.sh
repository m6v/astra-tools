#!/usr/bin/env bash

VERSION=1.02

NC='\033[0m' # No Color
Red='\033[0;31m' # Red
Green='\033[0;32m' # Green

checks=0
errors=0

usage(){
  echo "Использование: chkperms [-h|-v] ФАЙЛ..."
  echo "Проверяет соответствие прав доступа к файлам и каталогам матрице доступа"
  echo
  echo "  -h, --help    показать эту справку и выйти"
  echo "  -v, --verbose показывать успешные проверки"
  echo "  --version     показать информацию о версии и выйти"
  echo "  ФАЙЛ          файл с матрицей даступа"
}

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
  usage
  exit
fi

if [ -z "$file" ]; then
  echo "Ошибка: файл с матрицей доступа не задан" >&2
  exit
fi

total=$(cat $file | wc -l)
# The number of columns currently used in the terminal 
cols=$(tput cols)

# Присвоить переменной NAME имя дистрибутива
eval $(grep ^NAME /etc/os-release)
if [ "$NAME" == "Astra" ]; then
  # Исправить, чтобы в Астре это работало правилиьно, кол-во полей точно отличается!
  template="ls -dal --time-style=+ %s | cut -d' ' -f1,3,4,7-"
else
  template="ls -dal --time-style=+ %s | cut -d' ' -f1,3,4,7-"
fi

echo "Проверка прав доступа..."
while read -r line; do
    let "percent = $checks * 100 / $total"
    # Пересчитать количество знаков индикатора прогресса с учетом ширины экрана
    let "count = percent * ( cols - 5 ) / 100"
    # Варианты вывода знаков заполнения индикатора прогресса
    # см.: https://stackoverflow.com/questions/5349718/how-can-i-repeat-a-character-in-bash
    echo -ne "[${percent}%]"$(head -c $count < /dev/zero | tr '\0' '#')'\r'

    ((checks++))
    fname=$(echo $line  | cut -d' ' -f4-)
    if [ ! -e "${fname}" ]; then
      echo -e "${fname}...${Red}нет такого файла или каталога${NC}"
      continue
    fi
    # Имя файла обрамляем одинарными кавычками на случай наличия в нем пробелов
    # perms=$(eval "ls -dal --time-style=+ '${fname}' | cut -d' ' -f1,3,4,7-")
    perms=$(eval $(printf "$template" "'$fname'"))
    if [ "$line" = "$perms" ]; then
      if [ -n "$verbose" ]; then
        echo -e "${fname}...${Green}успешно${NC}"
      fi
    else
      ((errors++))
      echo -e "${fname}...${Red}ошибка${NC}"
    fi
done <$file

echo
echo "Проверено объектов "$checks", ошибок "$errors
