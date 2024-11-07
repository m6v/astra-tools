#!/usr/bin/env bash

VERSION=1.03

# Используемые escape-последовательности
none='\033[0m' # Нет цвета
red='\033[0;31m' # Красный
green='\033[0;32m' # Зеленый
EraseLine='\033[K' # Стереть от курсора до конца строки

checks=0
errors=0

usage(){
  echo "Использование: $(basename $0) [-h|-v|-p|--version] ФАЙЛ..."
  echo "Проверяет соответствие прав доступа к файлам и каталогам матрице доступа"
  echo
  echo "  -h, --help     показать эту справку и выйти"
  echo "  -v, --verbose  показывать успешные проверки"
  echo "  -p, --progress показать индикатор програсса выполнения"
  echo "  --version      показать информацию о версии и выйти"
  echo "  ФАЙЛ           файл с матрицей даступа"
}

progress(){
  percent=$(($1 * 100 / ${total}))
  # Количество знаков индикатора прогресса с учетом ширины терминала
  sharps=$(($1 * ${tcols} / ${total}))
  # escape-последовательность для повторения символа перед ней несколько раз (REP) \e[n;b
  # см.: https://invisible-island.net/xterm/ctlseqs/ctlseqs.pdf (стр. 12)
  printf [%d%%]"#\e[%d;b\r" $percent $sharps
}

# присваиваем переменной указатель на пустую операцию
show_progress=(:)

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      exit
      ;;
    -v|--verbose)
      verbose=true
      ;; 
    -p|--progress)
      # присваиваем переменной указатель на функцию отображения индикатора прогресса
      show_progress=(progress)
      ;;     
    --version)
      echo $(basename $0) $VERSION
      exit
      ;;
    *)
      file=$1
      ;;
  esac
  shift
done

if [ ! -f "$file" ]; then
  echo "Ошибка: файл с матрицей доступа не задан или не найден" >&2
  exit
fi

total=$(cat $file | wc -l)
# Число колонок в окне терминала 
tcols=$(tput cols)

get_astra_perms(){
  echo $(eval "pdp-ls -daM --time-style=+ $1 | cut -d' ' -f1,4-")
}

get_linux_perms(){
  echo $(eval "ls -dal --time-style=+ $1 | cut -d' ' -f1,3,4,7-")
}

# Присвоить переменной NAME имя дистрибутива
eval $(grep ^NAME /etc/os-release)
# Присвоить переменной get_os_perms указатель на нужную функцию в зависимости от ОС
if [ "$NAME" == "Astra Linux" ]; then
  # Исправить, чтобы в Астре это работало правилиьно, кол-во полей точно отличается!
  get_os_perms=(get_astra_perms)
else
  get_os_perms=(get_linux_perms)
fi

echo "Проверка прав доступа..."
while read -r line; do
  $show_progress $checks
  ((checks++))

  fname=$(echo $line | cut -d' ' -f4-)
  if [ ! -e "${fname}" ]; then
    echo -e "${fname}...${red}нет такого файла или каталога${none}"
    continue
  fi
  # Имя файла обрамляем одинарными кавычками на случай наличия в нем пробелов
  perms=$($get_os_perms "'$fname'")

  if [ "$line" != "$perms" ]; then
    ((errors++))
    echo -e "${fname}...${red}ошибка${none}${EraseLine}"
    continue  
  fi

  if [ -n "$verbose" ]; then
    # Вывести сообщение и затереть индикатор прогресса
    echo -e "${fname}...${green}успешно${none}${EraseLine}"
  fi
done <$file

echo "Проверено объектов "$checks", ошибок "$errors
