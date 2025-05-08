# -*- coding: utf-8 -*-

from datetime import datetime
from dateutil import parser, tz
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
import json
import logging
import os
import re
import socket
import sys
import subprocess

# Интервал времени между событиями с одинаковым идентификатором,
# в течении которого последующие события отбрасываются
DROP_TIME = 5
# Минимальный размер уведомления auditd, чтобы исключать неопознанные (did-unknown) события,
# например, "At 00:13:33 05.05.2025  did-unknown " (36 символов, включая последний пробел)
MIN_EVENT_SIZE = 40

hostname = socket.gethostname()
appname = os.path.basename(__file__).split(".")[0]

logging.basicConfig(filename="/var/log/%s.log" % appname,
                    format="%(asctime)s %(message)s",
                    datefmt="%Y-%m-%d %H:%M:%S",
                    level=logging.DEBUG)

"""
Парсеры сообщений syslog-ng, передаваемых в msg["MESSAGE"], и
формирующие в msg["notification"] строку из полей, разделенных символом ;
в которой первое поле время, второе - заголовок, последующие - текст уведомления
"""
class AstraEventsParser(object):
    def init(self, options):
        logging.info("%s is running..." % type(self).__name__)

        # Идентификатор и время последнего события
        self.last_message_id = ""
        self.last_message_dt = datetime.now(tz=tz.tzlocal())
        return True

    def parse(self, msg):
        try:
            record = json.loads(msg["MESSAGE"])
            # Установить приоритет сообщения (low, normal, critical)
            # в зависимости от приоритета события (debug, info, notice, warning, error, critical, alert, emergency)
            if record["PRIORITY"] in ("debug", "info", "notice"):
                priority = "low"
            elif record["PRIORITY"] == "warning":
                priority = "normal"
            else:
                priority = "critical"
            # В Astra Linux 1.7  используется syslog-ng 3.13 с syslog-ng-mod-python 2.7.16,
            # поэтому вместо datetime.fromisoformat, используем dateutil.parser
            dt = parser.parse(record["ISODATE"])
            # Получить из сообщения тип, название и идентификатор системного события
            for key in ("type_ru", "name_ru", "message_id"):
                globals()[key] = record["MSG"]["astra-audit"][key]
            # Если за короткий интервал времени подряд
            # пришло много сообщений с одним идентификатором,
            # показать первое сообщение и отбросить последующие дубликаты
            timedelta = (dt - self.last_message_dt).total_seconds()
            if message_id == self.last_message_id and timedelta < DROP_TIME:
                # logging.debug("Skip similar messages with message_id: %s" % message_id)
                return True
            self.last_message_id = message_id
            self.last_message_dt = dt
            # Сформировать уведомление одним элементом
            title = "Системное событие"
            body = ";".join((dt.strftime("%Y-%m-%d %H:%M:%S"),
                             hostname,
                             type_ru,
                             name_ru))
            msg["notification"] = ";".join((priority, title, body))
            return True
        except Exception as e:
            logging.error('%s get message "%s"' % (type(self).__name__, record))
            logging.exception(e)
            return False

    def deinit(self):
        logging.info("%s is stoped..." % type(self).__name__)
        return True


class AfickEventsParser(object):
    def __init__(self):
        pass

    def init(self, options):
        logging.info("%s is running..." % type(self).__name__)
        return True

    def parse(self, msg):
        try:
            # Первые 19 символов сообщения это дата и время
            dt = parser.parse(msg["MESSAGE"][:19], fuzzy_with_tokens=True)[0]

            results = {}
            for match in re.finditer(r'([a-z_]*)(\s:\s)(\d*)', msg["MESSAGE"]):
                results[match.group(1)] = match.group(3)

            title = "Результаты контроля целостности"
            if results["new"] != 0:
                priority = "normal"
            elif results["delete"] + results["changed"] != 0:
                priority = "critical"
            else:
                priority = "low"

            body = "{0};{1};Проверена целостность {2} объектов (новых: {3}, удаленных: {4}, измененных: {5})"\
                .format(dt.strftime("%Y-%m-%d %H:%M:%S"),
                        hostname,
                        results["compare"],
                        results["new"],
                        results["delete"],
                        results["changed"])

            msg["notification"] = ";".join((priority, title, body))

            return True
        except Exception as e:
            logging.exception(e)
            return False

    def deinit(self):
        logging.info("%s is stoped..." % type(self).__name__)
        return True


class RebusEventsParser(object):
    def __init__(self):
        pass

    def init(self, options):
        logging.info("%s is running..." % type(self).__name__)
        return True

    def parse(self, msg):
        try:
            # Первые 20 символов сообщения это дата и время
            dt = parser.parse(msg["MESSAGE"][:20], fuzzy_with_tokens=True)[0]

            # Текст и параметры сообщения (6 поле - какое-то цифровое значение)
            event, _, params = msg["MESSAGE"].split('|')[5:8]

            # Список в котором элементы соответствуют индексам
            # первых символов названия переменных
            indexes = [ match.start() for match in re.finditer(r'([a-zA-Z0-9_]*)=', params) ]
            indexes.append(len(params))

            # Добавить в глобальную область видимости переменные
            # из последнего поля сообщения
            for i in range(len(indexes)-1):
                key, value = params[indexes[i]:indexes[i+1]-1].split("=")
                globals()[key] = value

            # TODO Разобраться в каком поле сообщения задается уровень важности
            # и преобразовать его в priority
            priority = "low"
            title = sourceServiceName
            body = ";".join((dt.strftime("%Y-%m-%d %H:%M:%S"),
                             hostname,
                             event))
            msg["notification"] = ";".join((priority, title, body))
            return True
        except Exception as e:
            logging.exception(e)
            return False

    def deinit(self):
        logging.info("%s is stoped..." % type(self).__name__)
        return True


class AuditEventsParser(object):
    def __init__(self):
        pass

    def init(self, options):
        logging.info("%s is running..." % type(self).__name__)
        return True

    def parse(self, msg):
        try:
            # Получить время и идентификатор события в сообщении вида msg=audit(1116360555.329:2401771)
            match = re.findall('msg=audit\((.*?)\)', msg["MESSAGE"])[0]
            timestamp, eid = match.split(':')
            # Найти и вывести событие с идентификатором eid, полученное
            # за последние 10 минут (опция --start recent)
            process = subprocess.Popen(['ausearch', '-a', eid, '--start', 'recent', '--format', 'text', '--input-logs'], stdout=subprocess.PIPE)
            stdout, stderr = process.communicate()
            # если ausearch находит несколько событий с одинаковым eid,
            # он возвращает multiline string,  которую сплитим в список
            lines = stdout.splitlines()

            logging.debug("ausearch find next event(s) with eid=%s: %s" % (eid, ";".join(lines)))

            # Используем последнее из событий, найденных ausearch
            last_message = lines[-1]
            if len(last_message) > MIN_EVENT_SIZE:
                title = "Аудит событий"
                priority = "low"
                dt = datetime.strptime(last_message[3:22], '%H:%M:%S %d.%m.%Y')
                body = ";".join((dt.strftime("%Y-%m-%d %H:%M:%S"),
                                 hostname,
                                 last_message[23:]))
                msg["notification"] = ";".join((priority, title, body))
            return True
        except Exception as e:
            logging.exception(e)
            return False

    def deinit(self):
        logging.info("%s is stoped..." % type(self).__name__)
        return True

class CustomDbusService(dbus.service.Object):
    '''
    Класс для отправки широковещательных уведомлений в системную шину
    Для включения широковещательных уведомлений необходимо создать
    либо общий файл /etc/xdg/fly-notificationsrc,
    либо индивидуальные файлы ~/.config/fly-notificationsrc,
    содержащие строку ListenForBroadcasts=true в секции [Notifications]
    '''
    def __init__(self, bus, path):
        dbus.service.Object.__init__(self, bus, path)

    @dbus.service.signal(dbus_interface="org.kde.BroadcastNotifications", signature="a{sv}")
    def Notify(self, msg):
        '''
        Имя метода должно соответствовать имени отправляемого сигнала,
        а сообщение должно соответствовать объявленной сигнатуре a{sv},
        т.е быть словарем со строковыми ключами (string) и произвольными значениями (variant)
        Тело метода отсутствует, можно вставить логирование
        '''
        pass

    def send(self, line):
        try:
            logging.debug('%s get message "%s"' % (type(self).__name__,
                                                   line))
            priority, title = line.split(";")[:2]
            body = "\n".join(line.split(";")[2:])

            if priority == "critical":
                icon_name = "dialog-error"
            elif priority == "normal":
                icon_name = "dialog-warning"
            else:
                icon_name = "dialog-information"

            msg = {"appName": "Системные события",
                   "appIcon": icon_name,
                   "body": body,
                   "summary": title,
                   "timeout": 5000,
                   # "hints": "Text of hints",
                   # "uids": ['0', '1000']
                  }
            self.Notify(msg)
        except Exception as e:
            logging.exception(e)
            return False

class DbusSender(object):
    dbus_loop = DBusGMainLoop()
    bus = dbus.SystemBus(mainloop=dbus_loop)
    # то же можно сделать следующим образом:
    # DBusGMainLoop(set_as_default=True)
    # bus = dbus.SystemBus()
    path = "/"
    service = CustomDbusService(bus, path)

    def init(self, options):
        logging.info("%s is running..." % type(self).__name__)
        return True

    def send(self, msg):
        try:
            logging.debug('%s send message "%s"' % (type(self).__name__,
                                                    msg["MESSAGE"]))
            self.service.send(msg["MESSAGE"])
            return True
        except Exception as e:
            logging.exception(e)
            return False

    def deinit(self):
        logging.info("%s is stoped..." % type(self).__name__)
        return True
