#!/usr/bin/env bash

if [ $(id -u) -ne 0 ]; then
  echo "$(basename $0): запустите программу с правами суперпользователя"
  exit
fi

VERSION=1.08
ASTRA_RELEASE=$(lsb_release -rs | cut -b 1-3)

NC='\033[0m' # No Color
Red='\033[0;31m' # Red
Green='\033[0;32m' # Green

all_checks="status results"

usage(){
  echo "Использование: afick-check -h|-v|--version|ФАЙЛ"
  echo "Проверяет соответствие настроек средства регламентного контроля целостности эталонным, заданным в ФАЙЛе"
  echo
  echo "Аргументы, обязательные для длинных параметров, обязательны и для коротких"
  echo "  -s, --scan    выполнить контроль целостности и выйти"
  echo "  -h, --help    показать эту справку и выйти"
  echo "  -v, --verbose показать вывод средства регламентного контроля целостности"
  echo "  --version показать информацию о версии и выйти"
}

settings(){
  echo -n "Проверка настроек средства регламентного контроля целостности ..."
  diff -y $fname /etc/afick.conf > /tmp/afick.diff
  if [ $? -ne 0 ]; then
    echo -e "${Red}ошибка!${NC}"
    echo "Настройки средства регламентного контроля целостности не соответствуют эталонным" >&2
    echo "Сравните файл /etc/afick.conf с эталонным, устраните несоответствия и повторите проверку" >&2
    if [ -n "$verbose" ]; then
      cat /tmp/afick.diff
    fi
    return 1
  fi
}

status(){
  : '
    Функция проверяет состояние службы afick и код возврата последнего запуска.
    Если служба включена (enabled) и код возврата нулевой, проверка считается успешной
  '
  echo -n "Проверка состояния службы регламентного контроля целостности ..."
  result=$(systemctl is-enabled afick 2> /dev/null)
  if [ "$result" != "enabled" ]; then
    echo -e "${Red}ошибка!${NC}"
    echo "Служба регламентного контроля целостности не включена" >&2
    if [ ! -f "/etc/systemd/system/afick.service"]; then
      echo "Файл /etc/systemd/system/afick.service отсутствует" >&2
      return 1
    fi
    echo "Выполните команду systemctl enable afick и повторите проверку" >&2
    return 1
  fi

  if [ -n "$verbose" ]; then
    echo
    systemctl status --no-pager -l afick
  fi

  if [ -z "$(systemctl status afick | grep status=0/SUCCESS)" ]; then
    echo -e "${Red}ошибка!${NC}"
    echo "Последний запуск средства регламентного контроля целостности Afick завершен с ошибкой" >&2
    echo "Выполните команду systemctl status afick и проанализируйте логи" >&2
    return 1
  fi
}

scan(){
  echo -n "Контроль целостности ..."
  afick -k &> /tmp/afick.res
  result=$?

  if [ $result -ne 0 ]; then
    echo -e "${Red}ошибка!${NC}"
    # Пропустить в отчете строки с комментариями
    grep -v '^#' /tmp/afick.res
  else
    echo "${Green}успешно!${NC}"
  fi

  exit $result
}

results(){
  echo -n "Проверка результатов контроля целостности ..."
  last_res=$(grep -E 'Hash database' /var/log/syslog | tail -1)
  # Вывести дату и время последней проверки
  date=$(echo $last_res | cut -d' ' -f1-3)
  # Вывести сводку с результатами последней проверки
  # echo $last_res | grep -o '[a-z_]* : [0-9]*' | cut -d' ' -f1,3
  # echo $last_res | grep -o '[a-z_]* : [0-9]*;' | sed 's/\s:\s/=/g'
  for item in $(echo $last_res | grep -o '[a-z_]* : [0-9]*;' | sed 's/\s:\s/=/g')
    do
      eval $item
    done
  if [ $(($new+$delete+$changed)) -ne 0 ]; then
    echo -e "${Red}ошибка!${NC}"
    # Преобразовать дату из формата 'Nov 18 10:19:40' в '2024-11-18 10:19:40'
    echo 'Последняя проверка: '$(date -d"$date" "+%F %T")
    echo 'Новых: '$new', удаленных: '$delete', измененных: '$changed
    return 1
  fi
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -s|--scan)
      scan
      ;;
    -h|--help)
      usage
      exit
      ;;
    -v|--verbose)
      verbose=true
      ;;
    --version)
      echo afick-check $VERSION
      exit
      ;;
    *)
      fname=$1
      if [ ! -f $fname ]; then
        echo "afick-check:" $fname "нет такого файла"
        exit
      fi
      # Если файл с эталонными настройками задан, добавляем проверку сравнения с ним
      all_checks+=" settings"
      ;;
  esac
  shift
done

total=0  # Общее число проверок
failed=0 # Число неуспешных проверок

for check in $all_checks
  do
    ((total++))
    $check
    if [ $? -eq 0 ]; then
      echo -e "${Green}успешно!${NC}"
    else
      ((failed++))
    fi
  done
echo "Выполнено проверок ${total}, неуспешных ${failed}"

exit $failed
