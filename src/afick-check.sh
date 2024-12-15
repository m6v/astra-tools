#!/usr/bin/env bash

VERSION=1.11
ASTRA_RELEASE=$(lsb_release -rs | cut -b 1-3)

nc='\033[0m' # Нет цвета
red='\033[0;31m' # Красный
green='\033[0;32m' # Зеленый

checks="status syslog"

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

paths(){
    result=0
    for i in $paths; do
        if [ ! -e $i ]; then
            echo "$i не существует"
        fi
        # В файле afick.conf после пути к проверяемому объекту идет пробел или табуляция
        grep -Po "^$i[^ \t]*" afick.conf &> /dev/null
        if [ $? -ne 0 ]; then 
            echo "Целостность $i не контролируется" >&2
            ((result++))
        fi 
    done

    echo -n "Проверка списка объектов, целостность которых подлежит контролю ..."
    if [ $result -ne 0 ]; then
        echo -e "${red}ошибка!${nc}"
    fi

    return $result
}

status_new(){
    # TODO Сделать полноценный анализ кода возврата службы afick
    # afick -k возвращает четырехбитное значение в котором установка бита 0 означает наличие "битых" ссылок,
    # бита 1 - наличие измененных убъектов, бита 2 - удаленных объектов, бита 3 - новых объектов
    # но не факт, что systemd правильно интерпретирует код возврата
    result=$(systemctl status afick)
    case $result in
        0)
            return $result
            ;;
        4)
            echo "Служба регламентного контроля целостности не обнаружена" >&2
            ;;
    esac
    return $result
}

status(){
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
        echo "В журнале /var/log/syslog результаты контроля целостности не найдены"
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
