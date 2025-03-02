#!/usr/bin/env bash

VERSION=1.01

# Используемые escape-последовательности
nc='\033[0m' # Нет цвета
red='\033[0;31m' # Красный
green='\033[0;32m' # Зеленый

# Список создаваемых групп пользователей
groups="operators nachsmens technics"
# Список создаваемых учетных записей пользователей и их группы
# учетная запись администратора безопасности создается при установке ОС
users='operator:operators nachsmen:nachsmens technic:technics'
# Дефолтный пароль для создаваемых пользователей
DEFAULT_PASS='Aa123456'
# Список дополнительных групп для создаваемых пользователей (возможно еще нужны pulse и pulse-access)
DEFAULT_GROUPS='video,users,plugdev,floppy,dialout,cdrom,audio'

usage(){
    echo "Использование: $(basename $0) [КЛЮЧ]..."
    echo "Выполняет настройку комплекса средств защиты информации ОС Astra Linux SE"
    echo
    echo "Аргументы, обязательные для длинных параметров, обязательны и для коротких"
    echo "  -h, --hostname имя хоста"
    echo "  -e, --events   список флагов аудита успехов и отказов, по умолчанию ocxuew"
    echo "  -p, --passes   число проходов при очистке освобождаемых блоков файловой системы, по умолчанию 1"
    echo "  -v, --version  показать информацию о версии и выйти"
    echo "  -?, --help     показать эту справку и выйти"
}

show_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${green}успешно!${nc}"
    else
        echo -e "${red}ошибка!${nc}"
    fi
}

if [ $(id -u) -ne 0 ]; then
    echo "$(basename $0): запустите программу с правами суперпользователя"
    exit
fi

# Параметры по умолчанию (соответствуют требованиям для класса защищеннсти 1Г)
events=ocxuew
passes=1
# Имя учетной записи (администратора безопасности информации), созданной при инсталляции ОС
admin_name=$(id -n -u 1000)

while [ "$#" -gt 0 ]; do
    case $1 in
        -h|--hostname)
            hostname=$2
            shift
            ;;
        -e|--events)
            events=$2
            shift
            ;;
        -p|--passes)
            passes=$2
            shift
            ;;
        -v|--version)
            echo $(basename $0) $VERSION
            exit
            ;;
        -?|--help)
            usage
            exit
            ;;
        *)
            echo "$(basename $0): неверный ключ: $1"
            exit
            ;;
    esac
    shift
done

re='^[0-9]+$'
if ! [[ $passes =~ $re ]]; then
    echo "$(basename $0): неверный аргумент у параметра -p, --passes"
    exit
fi

# TODO Добавить все валидные символы
re='^[ocxuew]+$'
if ! [[ $events =~ $re ]]; then
    echo "$(basename $0): неверный аргумент у параметра -e, --events"
    exit
fi

# Если параметр hostname задан, проверить его валидность и изменить имя хоста
if [ -n "$hostname" ]; then
    re='^[a-zA-Z]+[a-zA-Z0-9\-]*'
    if ! [[ $hostname =~ $re ]]; then
        echo "$(basename $0): неверный аргумент у параметра -h, --hostname"
        exit
    fi
    echo -n "Настройка имени хоста..."
    hostnamectl set-hostname $hostname
    show_result $?
fi

echo $hostname $events $passes
exit

echo -n "Настройка локального репозитория..."
# закомментировать все незакомментированные ссылки на репозитории
sed -i 's/^\([^#].*\)/# \1/g' /etc/apt/sources.list
# добавить ссылку на локальный репозиторий, скопированный с установочного диска при установке системы
echo 'deb file:/srv/repo/alse/base stable main contrib non-free' >> /etc/apt/sources.list
apt update
show_result $?

echo -n "Настройка гарантированного удаления файлов и папок..."
if [ $passes -ne 0 ]; then
    # включить гарантированное удаление файлов и папок, чтобы в ext разделах  установился параметр secdel
    astra-secdel-control enable
    result=$?
    # заменить параметр secdel... на secdelrnd=1
    sed -i 's/secdel[^ ]*/secdelrnd=${passes}/g' /etc/fstab
# Если переменная passes имеен нулевое значение, отключить гарантированное удаление файлов и папок
else
    astra-secdel-control disable
    result=$?
fi
show_result $result

echo -n "Настройка очистки разделов подкачки..."
astra-swapwiper-control enable
show_result $?

echo -n "Настройка блокировки интерпретаторов кроме Bash для пользователей..."
astra-interpreters-lock enable
show_result $?

echo -n "Настройка запрета установки бита исполнения для всех пользователей, включая администраторов..."
astra-nochmodx-lock enable
show_result $?

echo -n "Настройка блокировки клавиш SysRq для всех пользователей, включая администраторов..."
astra-sysrq-lock enable
show_result $?

echo -n "Настройка блокировки трассировки ptrace для всех пользователей, включая администраторов..."
astra-ptrace-lock enable
show_result $?

echo -n "Настройка блокировки системных команд для пользователей..."
astra-commands-lock enable
show_result $?

echo -n "Настройка блокировки исполнения макросов libreoffice и VLC..."
astra-macros-lock enable
show_result $?

echo -n "Настройка дополнительной аутентификации при повышении привилегий (ввода пароля для sudo)..."
astra-sudo-control enable
show_result $?

echo -n "Настройка политики блокировки учетных записей..."
sed -i 's/pam_tally.so.*/pam_tally.so deny=6 unlock_time=1800/' /etc/pam.d/common-auth
show_result $?

echo -n "Настройка политики паролей..."
# Настройка сложности (длины и алфавита) паролей
sed -i 's/pam_cracklib.so.*/pam_cracklib.so retry=3 difok=3 minlen=8 lcredit=-1 ucredit=-1 dcredit=-1 ocredit=0/' /etc/pam.d/common-password
# Настройка максимального количества дней между сменами пароля
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
show_result 0

echo -n "Настройка правил протоколирования для пользователей..."
# Установка ключей регистрации, заданных в passes
useraud -mo $passes:$passes &>/dev/null
show_result $?

echo -n "Настройка периодичности ротации журналов (logrotate)..."
sed -i 's/^weekly/daily/' /etc/logrotate.conf
sed -i 's/^rotate.*/rotate 32/' /etc/logrotate.conf
show_result 0

echo -n "Настройка средства регламентного контроля целостности..."
sed -i 's/^report_syslog.*/report_syslog := yes/' /etc/afick.conf

# Юнит для запуска afick при загрузке ОС
# В /var/log/syslog вывод пишет всегда независимо от параметра report_syslog,
# возможно это особенность при запуске в качестве службы systemd
# Сводка результатов пишется в /var/lib/afick/history
cat << EOF > /etc/systemd/system/afick.service
[Unit]
Description=Another File Integrity Checker
# Запуск после монтирования локальных файловых систем
After=local-fs.target

[Service]
# При типе oneshot все последующие юниты будут ждать заверешения afick прежде чем запустятся,
# при типе simple  последующие юниты запускаются параллельно, не ожидая завершения afick
Type=simple
ExecStart=/bin/bash -c "afick -k &> /dev/null; exit 0"
# Считать сервис активным, несмотря на то, что процесс завершился
RemainAfterExit=true
# StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable afick &> /dev/null
show_result $?

echo -n "Создание групп пользователей..."
result=0
for i in $groups; do
    groupadd -f $i
    ((result+=$?))
done
show_result $result

echo -n "Создание пользователей..."
result=0
for i in $users; do
    user_name=$(echo $i | cut -d':' -f1)
    group_name=$(echo $i | cut -d':' -f2)
    # Чтобы не выводить сообщения при попытке создать пользователя с существующем именем, перенаправляем stderr в /dev/null
    useradd -g $group_name -G $DEFAULT_GROUPS -s /bin/bash -m -p $(openssl passwd -1 $DEFAULT_PASS) $user_name 2>/dev/null
    ((result+=$?))
done
show_result $result

echo -n "Генерация ssh-ключей администратора безопасности..."
mkdir /home/$(admin_name)/.ssh
ssh-keygen -f /home/${admin_name}/.ssh/id_rsa -q -N ""
result=$?
# Рекурсивно поменять владельца у ~/.ssh т.к. при выполнении под sudo будут root:root
chown -R ${admin_name}:${admin_name} /home/${admin_name}/.ssh
show_result $result

: '''
TODO После установки ОС на всех СВТ необходимо выполнить обмен ключами
SERVERS="arm-o server"

for SERVER in SERVERS; do
    # Copy our key the first time to allow
    sshpass -p $DEFAULT_PASS ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $USER@$SERVER || result=1

    # Непонятно, зачем удалять и заново отправлять открытые ключи
    # Clean the .ssh folder
    ssh $USER@$SERVER "rm -rf .ssh"

    # Add back our key, as we have remove the former authorized keys, along with the new one!
    sshpass -p $DEFAULT_PASS ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $USER@$SERVER || result=1
done
'''
# result=0
# show_result $result

# Если настраиваемый компьютер не АРМ-АБИ, выйти
if [ "$hostname" != "arm-abi" ]; then
    exit
fi

# Установка и настройка сервера обмена сообщениями по протоколу xmpp
apt install ejabberd -y
systemctl enable ejabberd
# Зарегистрировать пользователей admin и syslog-agent
ejabberdctl register admin localhost $DEFAULT_PASS
ejabberdctl register syslog-agent localhost $DEFAULT_PASS
# Назначить пользователю admin права администратора для чего
# в третьей строке после строки acl: заменить "" на "admin"
sed -i '/^acl:/{N;N;N;s/""/"admin"/}' /etc/ejabberd/ejabberd.yml
systemctl restart ejabberd

# Установка клиента обмена сообщениями по протоколу xmpp и сопутствующих библиотек
apt install psi-plus libsasl2-modules python-xmpp -y

# Создание именованного канала для передачи сообщенеий от парсеров клиенту отправки xmpp-sender
# (см. https://www.freedesktop.org/software/systemd/man/latest/tmpfiles.d.html),
echo 'p /tmp/syslog-mg.msg 0644 root root' > /etc/tmpfiles.d/syslog-ng.conf

cat << EOF > "/home/$admin_name/.config/autostart/psi-plus.desktop"
[Desktop Entry]
Version=1.1
Type=Application
Name=Psi+
Icon=psi-plus
Exec=/usr/bin/psi-plus
Hidden=false
EOF

# Не запрашивать собственную vcard при запуске psi-plus 
sed -i 's/<query-own-vcard-on-login type="bool">true/<query-own-vcard-on-login type="bool">false/' /home/$admin_name/.config/psi+/profiles/default/options.xml


