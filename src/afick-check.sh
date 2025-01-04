#!/usr/bin/env bash

VERSION=1.13
ASTRA_RELEASE=$(lsb_release -rs | cut -b 1-3)

CONFIG_FILE='/etc/afick.conf'

nc='\033[0m' # Нет цвета
red='\033[0;31m' # Красный
green='\033[0;32m' # Зеленый

checks="config status syslog"

usage(){
    echo "Использование: $(basename $0) [-h|-v|--version] [ФАЙЛ]"
    echo "Проверяет состояние службы регламентного контроля целостности, наличие результатов контроля в системном"
    echo "журнале и наличие объектов, указанных в ФАЙЛЕ или стандартном вводе, в списке контролируемых объектов"
    echo
    echo "Аргументы, обязательные для длинных параметров, обязательны и для коротких"
    echo "  -h, --help    показать эту справку и выйти"
    echo "  -v, --verbose показывать подробный вывод результатов проверок"
    echo "      --version показать информацию о версии и выйти"
}

config(){
    echo -n "Проверка настройки логирования результатов в системный журнал ..."

    # Считать значения директив из конфигурационного файла
    while read line; do
        declare $line
    # Значения директивам присваиваются с помощью оператора := который может отделяться необязательными пробелами
    done < <(grep -Po '^[a-zA-Z_]+\s*:=\s*[a-zA-Z/]+' $CONFIG_FILE | tr -d ': ')

    if [ "$report_syslog" != "yes" ]; then
        echo -e "${red}ошибка!${nc}"
        return 1
    fi
    # Далее можно проверять значения других директив конфигурационного файла
    return 0
}

paths(){
    # NB! Учесть, что в /etc/afick.conf могут быть символы подстановки
    result=0
    for path in $paths; do
        if [ ! -e $path ]; then
            echo "$path не существует"
        fi
        # В файле afick.conf после пути к проверяемому объекту идет пробел или табуляция
        grep -Po "^$path[^ \t]*" afick.conf &> /dev/null
        if [ $? -ne 0 ]; then
            echo "Целостность $path не контролируется" >&2
            ((result++))
        fi
    done

    echo -n "Проверка списка объектов, целостность которых подлежит контролю ..."
    if [ $result -ne 0 ]; then
        echo -e "${red}ошибка!${nc}"
    fi

    return $result
}

status(){
    : '
      Функция проверяет код возврата службы afick, если он нулевой, проверка считается успешной
      NB! Нулевой код не означает отсутсвия нарушений целостности контролируемых объектов, это
      лишь признак того, что проверка целостности выполнена (результаты контроля в /var/log/syslog)
      afick -k возвращает четырехбитное значение в котором установка битов с нулевого по третий означает наличие
      "битых" ссылок (бит 0), измененных объектов (бит 1), удаленных объектов (бит 2), новых объектов (бит 3)
    '
    echo -n "Проверка состояния службы регламентного контроля целостности ..."
    # Проверка кода возврата, значения кодов в спецификации Linux Standard Base Core Specification, Generic Part
    # https://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Core-generic/LSB-Core-generic.html#INISCRPTACT
    systemctl status afick &> /dev/null
    if [ $? -eq 4 ]; then
        # Program or service status is unknown. No such unit
        echo -e "${red}ошибка!${nc}"
        echo "Служба регламентного контроля целостности не обнаружена" >&2
        return 1
    fi

    # Т.к. systemctl status afick, возвращает не статус службы выводимый на экране,
    # парсим вывод и получаем из него статус (status) службы afick
    declare $(systemctl status afick | grep -Po "status=\d+" -m 1)
    if [ $status -ne 0 ]; then
        echo -e "${red}ошибка!${nc}"
        echo "Служба регламентного контроля целостности завершилась с ошибкой (Exit code=$status)" >&2
        return $status
    fi
    return 0
}

status_bak(){
    : '
      Функция проверяет состояние службы afick и код возврата последнего запуска.
      Если служба включена (enabled) и код возврата нулевой, проверка считается успешной
    '
    echo -n "Проверка состояния службы регламентного контроля целостности ..."
    result=$(systemctl is-enabled afick 2> /dev/null)
    if [ "$result" != "enabled" ]; then
        echo -e "${red}ошибка!${nc}"
        if [ -f "/etc/systemd/system/afick.service" ]; then
            echo "Служба регламентного контроля целостности не включена" >&2
            echo "Выполните команду systemctl enable afick и повторите проверку" >&2
        else
            echo "Служба регламентного контроля целостности не обнаружена" >&2
            echo "Файл /etc/systemd/system/afick.service отсутствует" >&2
        fi
        return 1
    fi

    if [ -n "$verbose" ]; then
        echo
        systemctl status --no-pager -l afick
    fi

    # TODO Переделать на анализ кода возврата: 0 - Ок, 4 - служба не найдена и т.п.
    if [ -z "$(systemctl status afick | grep status=0/SUCCESS)" ]; then
        echo -e "${red}ошибка!${nc}"
        echo "Последний запуск средства регламентного контроля целостности Afick завершен с ошибкой" >&2
        echo "Выполните команду systemctl status afick и проанализируйте логи" >&2
        return 1
    fi
}

syslog(){
    echo -n "Проверка журналирования результатов контроля целостности ..."
    # Получить сводку последней проверки целостности
    last_check=$(grep -E 'Hash database' /var/log/syslog | tail -1)
    if [ -z "$last_check" ]; then
        echo -e "${red}ошибка!${nc}"
        echo "В системном журнале результаты контроля целостности не найдены"
        return 1
    fi

    # Дата и время последней проверки целостности
    date=$(echo $last_check | cut -d' ' -f1-3)
    # Найти в сводке значения, соответствующие шаблону item : value; привести их к виду item=value;
    # и выполнить присвоение соответствующим переменным их значений
    for item in $(echo $last_check | grep -o '[a-z_]* : [0-9]*;' | sed 's/\s:\s/=/g'); do
        eval $item
    done
    # Наличие новых, удаленных или измененных объектов не считаем ошибкой средства контроля целостности
    if [ $(($new+$delete+$changed)) -ne 0 ]; then
        # Преобразовать дату из формата 'Nov 18 10:19:40' в '2024-11-18 10:19:40'
        echo "Последняя проверка: $(date -d"$date" "+%F %T"), новых: $new, удаленных: $delete, измененных: $changed"
    fi
}

while [ "$#" -gt 0 ]; do
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
            echo $(basename $0) $VERSION
            exit
            ;;
        *)
            fname=$1
            if [ ! -f $fname ]; then
                "$(basename $0): задан неправильный параметр или путь: $1"
                exit
            fi
            paths+=" $(cat $fname | tr '\n' ' ')"
            ;;
    esac
    shift
done

# Если в стандартном вводе есть данные, считаем их путями к объектам, целостность которых подлежит контролю
if read -t 0 _ ; then
    while IFS= read -r line; do
        paths+=" $line"
    done < /dev/stdin
fi


if [ -z "$paths" ]; then
    echo -e "Проверка списка объектов, целостность которых подлежит контролю ...${red}пропущена!${nc}"
else
   checks+=" paths"
fi

if [ $(id -u) -ne 0 ]; then
    echo "$(basename $0): запустите программу с правами суперпользователя"
    exit
fi

total=0  # Общее число проверок
failed=0 # Число неуспешных проверок

for check in $checks; do
    ((total++))
    $check
    if [ $? -eq 0 ]; then
        echo -e "${green}успешно!${nc}"
    else
        ((failed++))
    fi
done

echo "Выполнено проверок ${total}, неуспешных ${failed}"
exit $failed
