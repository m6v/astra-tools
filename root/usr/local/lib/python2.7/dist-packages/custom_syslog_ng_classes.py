# -*- coding: utf-8 -*-

from datetime import datetime
from dateutil import parser, tz
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

hostname = socket.gethostname()
appname = os.path.basename(__file__).split(".")[0]

logging.basicConfig(filename="/var/log/%s.log" % appname,
                    format="%(asctime)s %(pathname)s: %(message)s",
                    datefmt="%Y-%m-%d %H:%M:%S",
                    level=logging.DEBUG)


class AstraEventsParser(object):
    def init(self, options):
        logging.debug("%s is running..." % type(self).__name__)

        # Идентификатор и время последнего события
        self.last_message_id = ""
        self.last_message_dt = datetime.now(tz=tz.tzlocal())
        return True

    def parse(self, msg):
        """
        Парсер системного сообщения в msg["MESSAGE"],
        формирующий в msg["notification"] строку из полей, разделенных символом ;
        Первое поле время, второе - заголовок, последующие - текст уведомления
        """
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

            # Иногда за короткий интервал времени подряд идет много сообщений с одним идентификатором
            # В этом случае показываем первое событие и отбрасываем последующие дубликаты
            timedelta = (dt - self.last_message_dt).total_seconds()
            if message_id == self.last_message_id and timedelta < DROP_TIME:
                logging.debug("Skip similar messages with message_id: %s" % message_id)
                return True
            self.last_message_id = message_id
            self.last_message_dt = dt

            # Формируем уведомление одним элементом
            title = "Системное событие"
            body = ";".join((dt.strftime("%Y-%m-%d %H:%M:%S"),
                             hostname,
                             type_ru,
                             name_ru))
            msg["notification"] = ";".join((priority, title, body))
            return True

        except Exception as e:
            logging.exception(e)
            return False

    def deinit(self):
        logging.debug("%s is stoped..." % type(self).__name__)
        return True


class AfickEventsParser(object):
    def __init__(self):
        pass

    def init(self, options):
        logging.debug("%s is running..." % type(self).__name__)
        return True

    def parse(self, msg):
        """
        Парсер сообщения сводки контроля целостности afick в msg["MESSAGE"],
        формирующий в msg["notification"] строку из полей, разделенных символом ;
        Первое поле время, второе - заголовок, последующие - текст уведомления
        """
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

            body = "{0};{1};Проверена целостность {2} объектов \
            (новых: {3}, удаленных: {4}, измененных: {5})"\
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
        logging.debug("%s is stoped..." % type(self).__name__)
        return True


class RebusEventsParser(object):
    def __init__(self):
        pass

    def init(self, options):
        logging.debug("%s is running..." % type(self).__name__)
        return True

    def parse(self, msg):
        """
        Парсер сообщения ПК "Ребус-СОВ" в msg["MESSAGE"],
        формирующий в msg["notification"] строку из полей, разделенных символом ;
        Первое поле время, второе - заголовок, последующие - текст уведомления
        """
        try:
            # Первые 20 символов сообщения это дата и время
            dt = parser.parse(msg["MESSAGE"][:20], fuzzy_with_tokens=True)[0]

            # Текст и параметры сообщения (6 поле - какое-то цифровое значение)
            event, _, params = msg["MESSAGE"].split('|')[5:8]

            # Список в котором элементы соответствуют индексам первых символов названия переменных
            indexes = [ match.start() for match in re.finditer(r'([a-zA-Z0-9_]*)=', params) ]
            indexes.append(len(params))

            # Добавить в глобальную область видимости переменные из последнего поля сообщения
            for i in range(len(indexes)-1):
                key, value = params[indexes[i]:indexes[i+1]-1].split("=")
                globals()[key] = value

            # TODO Разобраться в каком поле сообщения задается его уровень важности
            # и преобразовать его в priority, а пока все low
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
        logging.debug("%s is stoped..." % type(self).__name__)
        return True


class AuditParser(object):
    def __init__(self):
        pass

    def init(self, options):
        logging.debug("%s is running..." % type(self).__name__)
        return True

    def parse(self, msg):
        try:
            # Получить время и идентификатор события в сообщении вида msg=audit(1116360555.329:2401771)
            # Используем нежадный (ленивый) поиск, т.к. в сообщении может быть несколько полей, заключенных в скобки
            match = re.findall('msg=audit\((.*?)\)', msg["MESSAGE"])[0]
            timestamp, eid = match.split(':')

            # С помощью ausearch найти и вывести в человекочитаемом виде событие с идентификатором eid
            # NB! Если стандартный ввод ausearch является каналом, поиск выполняется через stdin,
            # а не через журналы демона аудита, поэтому используем опцию --input-logs,
            # чтобы заставить ausearch выполнять чтение из журналов
            # параметр --start recent задает диапазон поиска в последние 10 минут, иначе могут находиться несколько событий с одинаковым eid
            process = subprocess.Popen(['ausearch', '-a', eid, '--format', 'text', '--start', 'recent', '--input-logs'], stdout=subprocess.PIPE)
            stdout, stderr = process.communicate()
            # При отсутствии сообщений в течении длительного времени, syslog генерирует MARK сообщения,
            # информирующие получателя о том, что соединение все еще работает
            # Периодичность MARK сообщений задается параметром mark-freq(), параметр mark-mode() устанавливает режим генерации,
            # в т.ч. отключение см. стр. 201 The syslog-ng Open Source Edition 3.8 Administrator Guide)
            # ausearch не находит MARK сообщений по идентификатору, поэтому пустые сообщения выводить не нужно
            if stdout:
                # Если в логах обнаруживается несколько событий с одним eid
                # нужно брать предпоследнее stdout.split('\n')[-2],
                # т.к. последнее это пустая строка
                title = "Аудит событий"
                priority = "low"
                dt = datetime.strptime(stdout[3:22], '%H:%M:%S %d.%m.%Y')
                body = ";".join((dt.strftime("%Y-%m-%d %H:%M:%S"),
                                 hostname,
                                 stdout[23:]))
                msg["notification"] = ";".join((priority, title, body))
            return True
        except Exception as e:
            # Такой вызов обеспечивает вывод стека трассировки
            logging.exception(e)
            return False

    def deinit(self):
        logging.debug("%s is stoped..." % type(self).__name__)
        return True


class GdbusSender(object):
    def send(self, msg):
        '''
        Отправка широковещательных уведомлений с помощью gdbus
        NB! Для включения широковещательных уведомлений необходимо создать
        конфигурационные файлы ~/.config/fly-notificationsrc и /etc/xdg/fly-notificationsrc,
        содержащие строки
        [Notifications]
        ListenForBroadcasts=true
        '''
        try:
            priority, title = msg["MESSAGE"].split(";")[:2]
            body = "\n".join(msg["MESSAGE"].split(";")[2:])
            subprocess.call("gdbus emit --system --object-path / --signal org.kde.BroadcastNotifications.Notify \"{'appName': <'my_app'>, 'appIcon': <'dialog-information'>, 'body': <'%s'>, 'summary': <'%s'>, 'uids': <['0', '1000']>} \"" % (body, title), shell=True)
            return True
        except Exception as e:
            logging.exception(e)
            return False
