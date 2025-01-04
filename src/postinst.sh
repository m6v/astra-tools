#!/bin/bash

# Используемые escape-последовательности
nc='\033[0m' # Нет цвета
red='\033[0;31m' # Красный
green='\033[0;32m' # Зеленый

# Дефолтный пароль для создаваемых пользователей
PASS='Aa123456'
# Список дополнительных групп для создаваемых пользователей
DEFAULT_GROUPS='video,users,plugdev,floppy,dialout,cdrom,audio'

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

echo -n "Настройка гарантированного удаления файлов и папок..."
# включить гарантированное удаление файлов и папок, чтобы в ext разделах установился параметр secdel
astra-secdel-control enable
show_result $?
# заменить параметр secdel... на secdelrnd=1
sed -i 's/secdel[^ ]*/secdelrnd=1/g' /etc/fstab

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

echo -n "Настройка периодичности ротации журналов (logrotate)..."
sed -i 's/^weekly/daily/' /etc/logrotate.conf
sed -i 's/^rotate.*/rotate 32/' /etc/logrotate.conf
show_result 0

echo -n "Настройка средства срегламентного контроля целостности..."
sed -i 's/report_syslog := no/report_syslog := yes/' /etc/afick.conf

# Создание юнита для запуска afick при загрузке ОС
# В /var/log/syslog вывод пишет всегда независимо от параметра report_syslog,
# возможно это особенность systemd. Сводка результатов пишется в /var/lib/afick/history
cat << EOF > /etc/systemd/system/afick.service
[Unit]
Description=Another File Integrity Checker
# After=network.target
# Запуск после монтирования локальных файловых систем
After=local-fs.target

[Service]
# При типе oneshot все последующие юниты будут ждать заверешения afick прежде чем запустятся,
# при типе simple  последующие юниты запускаются параллельно, не ожидая завершения afick
Type=oneshot
ExecStart=/bin/bash -c "afick -k &>> /dev/null; exit 0"
# Считать сервис активным, несмотря на то, что процесс завершился
RemainAfterExit=true
# StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable afick
show_result $?

echo -n "Включение ssh-сервера..."
# Задержка, чтобы сервис успел включиться. Возможно дело не в ней, но ранее
# после первой перезагрузки ssh был отключен!?
sleep 3
systemctl enable ssh
show_result $?

echo -n "Создание групп пользователей..."
result=0
groups="operators nachsmens technics"
for i in $groups; do
    groupadd -f $i
    ((result+=$?))
done
show_result $result

echo -n "Создание пользователей..."
users='operator:operators nachsmen:nachsmens technic:technics'
result=0
for i in $users; do
    user_name=$(echo $i | cut -d':' -f1)
    group_name=$(echo $i | cut -d':' -f2)
    # Чтобы не выводить сообщения при попытке создать пользователя с существующем именем, перенаправляем stderr в /dev/null
    useradd -g $group_name -G $DEFAULT_GROUPS -s /bin/bash -m -p $(openssl passwd -1 $PASS) $user_name 2>/dev/null
    ((result+=$?))
done
show_result $result

echo -n "Настройка политики блокировки учетных записей..."
sed -i 's/pam_tally.so.*/pam_tally.so deny=6 unlock_time=1800/' /etc/pam.d/common-auth
show_result $?

echo -n "Настройка политики паролей..."
# Сделать необходимые настройки
show_result 0

# TODO Добавить настройку регистрации событий
