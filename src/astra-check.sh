#!/usr/bin/env bash

VERSION=1.11
ASTRA_RELEASE=$(lsb_release -rs | cut -b 1-3)

# Используемые escape-последовательности
nc='\033[0m' # Нет цвета
red='\033[0;31m' # Красный
green='\033[0;32m' # Зеленый

default_checks="audit_parms swapwiper_control secdel_control \
            nochmodx_lock interpreters_lock macros_lock ptrace_lock sysrq_lock shutdown_lock \
            passwords_policy blocking_policy logrotate_parms parsec_tests"

usage(){
    echo "Использование: $(basename $0) [-l|-h|-v|-c КЛАСС] [ПРОВЕРКИ]..."
    echo "Проверяет настройки комплекса средств защиты информации ОС Astra Linux SE"
    echo
    echo "Аргументы, обязательные для длинных параметров, обязательны и для коротких"
    echo "  -c, --class КЛАСС задать класс защищенности АС: 1А|1Б|1В|1Г|1Д|2А|2Б|3А|3Б"
    echo "  -l, --list        показать список проверок и выйти"
    echo "  -h, --help        показать эту справку и выйти"
    echo "  -v, --version     показать информацию о версии и выйти"
    echo "Если ПРОВЕРКИ не заданы, выполняются все проверки"
}

audit_parms(){
    echo -n "Проверка настроек аудита событий ..."
    if [ -z "$(useraud -o)" ]; then
        echo -e "${red}ошибка!${nc}"
        echo "Аудит событий не включен" >&2
        return 1
    else
        sucess_events=($(useraud -on | cut -d: -f1))
        fail_events=($(useraud -on | cut -d: -f2))
        if [ $(($sucess_events & $((audflags)))) != $((audflags)) ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Настройки аудита событий не соответствуют эталону" >&2
            return 1
        fi
        if [ $(($fail_events & $((audflags)))) != $((audflags)) ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Настройки аудита событий не соответствует эталону" >&2
            return 1
        fi
    fi
    return 0
}

# Проверки настроек политик безопасности с помощью инструментов командной строки astra-safepolicy
# см.: https://wiki.astralinux.ru/pages/viewpage.action?pageId=109020865

swapwiper_control(){
    echo -n "Проверка очистки разделов страничного обмена ..."
    swapconf=/etc/parsec/swap_wiper.conf
    if [ $ASTRA_RELEASE == "1.6" ]; then
        # Параметр q используется, чтобы ничего не писать в stdout, проверяется только код возврата
        grep -q ENABLED=Y $swapconf
        if [ $? -ne 0 ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Очистка разделов страничного обмена не включена" >&2
            return 1
        fi
    else
        astra-swapwiper-control status 1> /dev/null
        if [ $? -ne 0 ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Очистка разделов страничного обмена не включена" >&2
            return 1
        fi
    fi

    ignored_part=$(grep IGNORE= $swapconf | cut -d'"' -f2)
    if [ -n "$ignored_part" ]; then
        echo -e "${red}ошибка!${nc}"
        echo "Игнорируется раздел подкачки $ignored_part" >&2
        return 1
    fi
    return 0
}

secdel_control(){
    echo -n "Проверка очистки освобождааемых блоков файловой системы ..."
    if [ $ASTRA_RELEASE == "1.6" ]; then
        :
    else
        astra-secdel-control status 1> /dev/null
        if [ $? -ne 0 ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Очистка освобождаемых блоков файловой системы не включена" >&2
            return 1
        fi
    fi
    # Проверка гарантированного удаления файлов и папок на всех разделах с файловой системой семейства ext
    while read line; do
        echo $line | grep -q ext
        if [ $? -eq 0 ]; then
            secdelrnd=$(echo $line | grep -oE "secdelrnd=[0-9]")
            if [ -z "$secdelrnd" ]; then
                echo -e "${red}ошибка!${nc}"
                echo "Очистка освобождаемых блоков не включена на разделе $(echo $line | cut -d' ' -f1)" >&2
                return 1
            fi
        fi
    done < /etc/fstab
    return 0
}

mac_control(){
    echo -n "Проверка режима МРД (мандатного управления доступом) ..."
    max_ilev=$(grep -Po 'parsec.max_ilev=\d*' /proc/cmdline | cut -d= -f2)
    if [ $ASTRA_RELEASE == "1.6" ]; then
        if [ -z "$max_ilev" ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Режим МРД не включен" >&2
            return 1
        fi
    else
        astra-mac-control is-enabled 1> /dev/null
        if [ $? -ne 0 ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Режим МРД не включен!" >&2
            return 1
        fi
    fi

    if [ $max_ilev -eq 0 ]; then
        echo -e "${red}ошибка!${nc}"
        echo "Максимально допустимый уровень целостности имеет нулевое значение" >&2
        return 1
    fi
    return 0
}

nochmodx_lock(){
    echo -n "Проверка блокировки установки бита исполнения ..."
    if [ $ASTRA_RELEASE == "1.6" ]; then
        if [ $(cat /parsecfs/nochmodx) -eq 0 ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Блокировка установки бита исполнения не включена" >&2
            return 1
        fi
    else
        astra-nochmodx-lock is-enabled 1> /dev/null
        if [ $? -ne 0 ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Блокировка установки бита исполнения не включена" >&2
            return 1
        fi
    fi
    return 0
}

interpreters_lock(){
    echo -n "Проверка блокировки интерпретаторов ..."
    if [ $ASTRA_RELEASE == "1.6" ]; then
        # Здесь и в аналогичных проверках, если блокировка никогда не включалась,
        # то возвращается сообщение об ощибке, в стандартный вывод ничего не пишется
        # Если проверяемая блокировка хоть однажды былы включена,
        # то в зависимости от текущей установки возвращается enabled или disabled
        result=$(systemctl is-enabled astra-interpreters-lock 2> /dev/null)
        if [ "$result" != "enabled" ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Блокировка интерпретаторов не включена" >&2
            return 1
        fi
    else
        astra-interpreters-lock is-enabled 1> /dev/null
        if [ $? -ne 0 ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Блокировка интерпретаторов не включена" >&2
            return 1
        fi
    fi
    return 0
}

macros_lock(){
    echo -n "Проверка блокировки макросов ..."
    if [ $ASTRA_RELEASE == "1.6" ]; then
        result=$(systemctl is-enabled astra-macros-lock 2> /dev/null)
        if [ "$result" != "enabled" ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Блокировка макросов не включена" >&2
            return 1
        fi
    else
        astra-macros-lock is-enabled 1> /dev/null
        if [ $? -ne 0 ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Блокировка макросов не включена" >&2
            return 1
        fi
    fi
    return 0
}

ptrace_lock(){
    : '
      Функция проверяет значение вывод команды systemctl is-enabled astra-ptrace-lock (для Astra Linux SE 1.6)
      или значение, возвращаемое командой astra-ptrace-lock is-enabled (для Astra Linux SE 1.7)
    '
    echo -n "Проверка блокировки трассировки ptrace ..."
    if [ $ASTRA_RELEASE == "1.6" ]; then
        result=$(systemctl is-enabled astra-ptrace-lock 2> /dev/null)
        if [ "$result" != "enabled" ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Блокировка трассировки ptrace не включена" >&2
            return 1
        fi
    else
        astra-ptrace-lock is-enabled 1> /dev/null
        if [ $? -ne 0 ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Блокировка трассировки ptrace не включена" >&2
            return 1
        fi
    fi
    return 0
}

sysrq_lock(){
    : '
      Функция проверяет значение параметра ядра sysrq (для Astra Linux SE 1.6)
      или значение, возвращаемое командой astra-sysrq-lock is-enabled (для Astra Linux SE 1.7)
    '
    echo -n "Проверка блокировки клавиш SysRq ..."
    if [ $ASTRA_RELEASE == "1.6" ]; then
        if [ $(cat /proc/sys/kernel/sysrq) -ne 0 ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Блокировка клавиш SysRq не включена" >&2
            return 1
        fi
    else
        astra-sysrq-lock is-enabled 1> /dev/null
        if [ $? -ne 0 ]; then
            echo -e "${red}ошибка!${nc}"
            echo "Блокировка клавиш SysRq не включена" >&2
            return 1
        fi
    fi
    return 0
}

shutdown_lock(){
    echo -n "Проверка блокировки отключения питания ..."
    # Параметр AllowShutdown в секциях [X-:*-Core] и [X-*-Core] (разрешение локального и удаленного выключения питания соответственно)
    # файла /etc/X11/fly-dm/fly-dmcc может принимать значения All, Root или None ("Всем", "Только администратору" или "Никому")
    # В Astra Linux 1.6 astra-shutdown-lock не возвращает текущий статус, только включение или выключение, поэтому парсим вручую
    allow_shutdown=$(python3 -c "import configparser; c = configparser.ConfigParser(); c.read('/etc/X11/fly-dm/fly-dmrc'); print(c['X-*-Core']['AllowShutdown'])")
    if [ $allow_shutdown == "All" ]; then
        echo -e "${red}ошибка!${nc}"
        # echo "Блокировка отключения питания не включена" >&2
        return 1
    fi
    : ' # Т.к. блокировка локального отключения питания не нужна пропускаем дальнейшую проверку
        # В Astra Linux 1.6 astra-shutdown-lock is-enable не предусмотрена
    if [ $ASTRA_RELEASE == "1.7" ]; then
        astra-shutdown-lock is-enabled 1> /dev/null
        if [ $? -ne 0 ]; then
            echo -e "${red}ошибка!${nc}"
            # echo "Блокировка отключения питания не включена" >&2
            return 1
        fi
    '
    return 0
}

passwords_policy(){
    : '
      Функция проверяет значения параметра PASS_MAX_DAYS в файле /etc/login.defs
      и параметров minlen, lcredit, ucredit и dcredit в файле /etc/pam.d/common-password
      Если параметры PASS_MAX_DAYS имеет значения 90, minlen - значение 8,
      параметры lcredit, ucredit и dcredit имеют ненулевые значения, то проверка считается успешной
    '
    result=0
    while read line; do
        # NB! Начиная с Астры 1.6-10 переменные LOGIN_RETRIES и LOGIN_TIMEOUT задаются, но не используются!
        # Можно будет упростить код, здесь оставлено для примера парсинга переменных,
        # задаваемых в формате KEY VALUE (количество пробелов между именем и значением произвольное) по одной в строке
        echo $line | grep -q -E '^PASS_MAX_DAYS|^LOGIN_RETRIES|^LOGIN_TIMEOUT'
        if [ $? -eq 0 ]; then
            key=$(echo $line | cut -d' '  -f1)
            value=$(echo $line | cut -d' ' -f2)
            declare $key=$value
        fi
    done < /etc/login.defs

    if [ $PASS_MAX_DAYS -ne 90 ]; then
        echo "Максимальное количество дней между сменами пароля задано неверно" >&2
        ((result++))
    fi

    for line in $(grep pam_cracklib.so /etc/pam.d/common-password | awk '{for(i=1;i<=NF;i++) {if(match($i,/=/)) {print $i} } }'); do
        key=$(echo $line | cut -d'='  -f1)
        value=$(echo $line | cut -d'=' -f2)
        declare $key=$value
    done

    # echo $minlen $lcredit $ucredit $dcredit

    if [ $minlen -lt 8 ]; then
        echo "Требование к минимальной длине пароля задано неверно" >&2
        ((result++))
    fi

    # В этой и последующих проверках значения могут быть не установлены,
    # в этом случае им присваивается дефолтное значение ноль, а затем проверяется на равенство нулю
    if [ ${lcredit:-0} -eq 0 ]; then
        echo "Требование к количеству строчных букв в пароле задано неверно" >&2
        ((result++))
    fi

    if [ ${ucredit:-0} -eq 0 ]; then
        echo "Требование к количеству заглавных букв в пароле задано неверно"
        ((result++))
    fi

    if [ ${dcredit:-0} -eq 0 ]; then
        echo "Требование к количеству цифр букв в пароле задано неверно" >&2
        ((result++))
    fi
  
    # Вывести сообщение в конце теста, т.к. в процессе его выполнения могут выводиться предупреждающие сообщения
    echo -n "Проверка политики паролей ..."
    if [ $result -ne 0 ]; then
        echo -e "${red}ошибка!${nc}"
    fi
    return $result
}

blocking_policy(){
    : '
      Функция проверяет значения параметров deny и unlock_time в файле /etc/pam.d/common-account
      Если параметр deny меньше или равен 3, а unlock_time больше или равен 1800, то проверка считается успешной
    '
    # NB! В Астре 1.7.4 файл /etc/pam.d/common-auth
    # Распарсить файл на пары ключ=значение и создаем переменные с соответствующими именами и значениями
    result=0
    for line in $(grep pam_tally.so /etc/pam.d/common-account | awk '{for(i=1;i<=NF;i++) {if(match($i,/=/)) {print $i} } }'); do
        key=$(echo $line | cut -d'='  -f1)
        value=$(echo $line | cut -d'=' -f2)
        declare $key=$value
    done

    # Проверить значения переменных $deny и $unlock_time
    if [ -z "$deny" ] || [ -z "$unlock_time" ]; then
        echo "Число неуспешных попыток аутентификации и/или период блокировки не заданы" >&2
        result=1
    else
        if [ $deny -gt 6 ]; then
            echo "Число неуспешных попыток аутентификации до блокирования учетной записи задано неверно" >&2
            ((result++))
        fi
        if [ $unlock_time -lt 1800 ]; then
            echo "Период разблокирования задан неверно" >&2
            ((result++))
        fi

        # Аналогичный параметр per_user устанавливается в файле /etc/pam.d/common-auth
        if [ -n "$(grep per_user /etc/pam.d/common-account)" ]; then
            echo "Назначены индивидуальные настройки параметров блокировки учетных записей" >&2
            ((result++))
        fi
    fi

    # Выводим сообщение в конце теста, т.к. в процессе его выполнения могут выводиться предупреждающие сообщения
    echo -n "Проверка политики блокировки учетных записей ..."
    if [ $result -ne 0 ]; then
        echo -e "${red}ошибка!${nc}"
    fi
    return $result
}

logrotate_parms(){
    : '
      Функция проверяет наличие в файле /etc/logrotate.conf параметра daily и значение параметра rotate
      если параметр daily задан, а параметр rotate больше или равен 32, то проверка считается успешной
    '
    echo -n "Проверка периодичности ротации журналов регистрации событий ..."
    result=0
    if [ -z "$(grep -E '^daily' /etc/logrotate.conf)" ]; then
        ((result++))
    fi

    if [ -z "$(grep -E '^rotate' /etc/logrotate.conf)" ]; then
        ((result++))
    elif [ $(grep -E '^rotate' /etc/logrotate.conf | cut -d" " -f2) -lt 32 ]; then
        ((result++))
    fi

    if [ $result -ne 0 ]; then
        echo -e "${red}ошибка!${nc}"
        echo "Параметры периодичности ротации журналов регистрации событий настроены неверно" >&2
        echo "Проверьте файл /etc/logrotate.conf" >&2
    fi
    return $result
}

parsec_tests(){
    : '
      Функция проверяет, что пакет parsec-tests установлен
    '
    echo -n "Проверка установки средств тестирования подсистемы безопасности PARSEC ..."
    if [ -z "$(dpkg -l | grep parsec-tests)" ]; then
        echo -e "${red}ошибка!${nc}"
        echo "Средства тестирования подсистемы безопасности PARSEC не установлены" >&2
        return 1
    fi
}

show_groups(){
    : '
      Функция выводит локальные группы пользователей, созданные после установки ОС
    '
    getent group | awk -F: '{ if ($3 >= 1000 && $3 < 60000) printf "%s ", $1}'; echo
    which ald-admin 1> /dev/null
        # Если есть команда ald-admin, то вывести доменные группы пользователей
        if [ $? -eq 0 ]; then
            echo "Доменные группы пользователей:"
            ald-admin group-list
        fi
}

show_users(){
    : '
      Функция выводит пользователей, имеющих право интерактивного входа в систему
    '
    getent passwd | sort | awk -F: '{if (match($NF, "/bin/(ba)?sh")) { system("groups " $1); system("pdpl-user " $1)}}' 
    # Если есть команда ald-admin, то вывести доменных пользователей
    which ald-admin 1> /dev/null
    if [ $? -eq 0 ]; then
        echo "Доменные пользователи:"
        ald-admin user-list | awk '{system ("groups "$1); system("sudo pdpl-user " $1)}'
    fi
}

check_users(){
    : '
      Функция сравнивает эталонные настройки учетных записей пользователей,
      сохраненные в файле users.lst, с текущими настройками
    '
    echo -n "Проверка учетных записей пользователей, созданных после установки системы ..."
    # Учетные записи сортируются в алфавитном порядке, т.к. важен не порядок их создания, а само наличие и правильные настройки
    # В дополнение к оболочке /bin/bash проверяем /bin/sh, т.к. в некоторых случаях может быть установлена она
    diff=$(getent passwd | sort | awk -F: '{if (match($NF, "/bin/(ba)?sh")) { system("groups " $1); system("pdpl-user " $1)}}' | diff -y - users.lst)
    if [ $? -ne 0 ]; then
        echo -e "${red}ошибка!${nc}"
        echo "Настройки учетных записей пользователей не соответствуют эталонным" 
        getent passwd | sort | awk -F: '{if ($NF=="/bin/bash") { system("groups " $1); system("pdpl-user " $1)}}' | diff -y - users.lst
        return 1
    fi
}

hosts_identification(){
    : '
      Функция проверяет сетевое взаимодействие с хостами, адреса которых есть в arp-таблице
    '
    result=0
    ip n | awk '{system("ping -c 1 " $1)}'
    if [ $? -ne 0 ]; then
        ((result++))
    fi
    return $result
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--class)
         # У параметра -c обязательный аргумент класс защищенности АС
            class=$2
            shift
            ;;
        -l|--list)
            # Вывести проверки по умолчанию и проверку режима МРД
            echo $default_checks mac_control | tr " " "\n" | sort | tr "\n" " "
            echo
            exit
            ;;
        -h|--help)
            usage
            exit
            ;;
        -v|--version)
            echo $(basename $0) $VERSION
            exit
            ;;
        *)
            # Проверить, что функция с именем $1 определена в скрипте или системе
            if [ "$(type -t $1)" == "function" ]; then
                selected_checks+=" $1"
            else
                echo "$(basename $0): неизвестный параметр или проверка: $1"
                usage
                exit
            fi
            ;;
    esac
    shift
done

# Если проверки не заданы, выполняем все
if [ -z "$selected_checks" ]; then
    selected_checks=$default_checks
fi

# Класс защищенности по умолчанию 1Г
if [ -z "$class" ]; then
    class="1Г"
fi

# Установить флаги аудита в зависимости от класса защищенности
case $class in
    1Д|2Б|3Б)
        # регистрация входа (выхода) субъектов доступа в систему (из системы) или загрузки (останова) системы (выполняется другими средствами)
        audflags=0x00000 
        ;;
    3А) # в дополнение к требованиям классов 1Д, 2Б, 3Б
        # регистрация выдачи печатных (графических) документов на "твердую" копию (выполняется другими средствами)
        audflags=0x00000
        ;;
    1Г|2А)
        # в дополнение к требованиям класса 3А
        # регистрация запуска (завершения) программ и процессов, предназначенных для обработки защищаемых файлов
        # регистрация попыток доступа программных средств (программ, процессов, задач, заданий) к защищаемым файлам
        # регистрация попыток доступа программных средств к дополнительным защищаемым объектам доступа
        audflags=0x1800f
        ;;
    1В)
        # в дополнение к требованиям классов 1Г, 2А
        # регистрация изменений полномочий субъектов доступа и статуса объектов доступа 
        audflags=0x1983f
        ;;
    1А|1Б)
        # в дополнение к требованиям класса 1В
        # регистрация запуска (завершения) всех программ и процессов (заданий, задач)
        audflags=0x1983f
        ;;
    *)
        echo "$(basename $0): задан несуществующий класс АС: $class"
        usage
        exit
        ;;
esac

# Добавить проверку режима МРД для классов защищенности 1А, 1Б, 1В и 2А
if [[ "1А1Б1В2А" =~ $class ]] && [[ ! $selected_checks =~ "mac_control" ]]; then
    selected_checks+=" mac_control"
fi

total=0  # Общее число проверок
failed=0 # Число неуспешных проверок

if [ $(id -u) -ne 0 ]; then
    echo "$(basename $0): запустите программу с правами суперпользователя"
    exit
fi

# Запуск выбранных проверок
for check in $selected_checks
    do
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
