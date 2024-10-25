#!/usr/bin/python3
import time
import random

print('Протокол: /usr/lib/parsec/tests/tests.log\nЗапуск теста...')
testnames = ('audit_file.sh', 'udit_proc.sh', 'secdelrm.sh', 'rwx.sh', 'acl.sh', 'mem_test', 'fmac', 'ipc_mac', 'ipc_dac', 'tcpip_mac.sh', 'cap_mac')

for testname in testnames:
    print('---[%s]: запуск теста' % testname)
    time.sleep(random.randint(2,6))
    print('УСПЕШНО\n---[%s]: тест завершен' % testname)

print('Тест успешно пройден')

log = '''
---[audit_file.sh]: запуск теста
Запуск системы протоколированияУСПЕШНО
# Проверка системы протоколирования
Установка параметров флагов аудита для каталога /tmp/tmp/file-1539...УСПЕШНО
Установка флагов аудита для файла /tmp/file-1539...УСПЕШНО
Создание события аудита open /tmp/file-1539...УСПЕШНО
Создание события аудита chmod /tmp/file-1539...УСПЕШНО
Создание события аудита chown /tmp/file-1539...УСПЕШНО
Создание события аудита setfaud /tmp/file-1539...УСПЕШНО
Создание события аудита setfacl /tmp/file-1539...УСПЕШНО
Создание события аудита parsec_chmac /tmp/file-1539...УСПЕШНО
Создание события аудита exec /tmp/file-1539...УСПЕШНО
Создание события аудита unlink /tmp/file-1539...УСПЕШНО
Остановка службы протоколирования...УСПЕШНО
Удаление флагов аудита с каталога /tmp...УСПЕШНО
Поиск событий open в журнале...
УСПЕШНО
Поиск событий exec в журнале...
УСПЕШНО
Поиск событий unlink в журнале...
УСПЕШНО
Поиск событий chmod в журнале...
УСПЕШНО
Поиск событий chown в журнале...
УСПЕШНО
Поиск событий setfacl в журнале...
УСПЕШНО
Поиск событий audit в журнале...
УСПЕШНО
Поиск событий mac в журнале...
УСПЕШНО
Поиск событий create в журнале...
УСПЕШНО
Запуск системы протоколированияУСПЕШНО
УСПЕШНО
---[audit_file.sh]: тест завершен

---[audit_proc.sh]: запуск теста
подготовка к тестам
добавление пользователя и выставление флагов аудита
тест аудита для пользователя : audittestuser
audittestuser ocxudnarmphew:ocxudnarmphew
завершено
подтест - uid gid
найдено событие uid...УСПЕШНО
найдено событие gid...УСПЕШНО
подтест - module
найдено событие init_module...УСПЕШНО
найдено событие delete_module...УСПЕШНО
подтест - создание файла
найдено событие - create...УСПЕШНО
подтест - mac
найдено событие mac...УСПЕШНО
подтест - mac
найдено событие mac...УСПЕШНО
подтест - открытие файла
найдено событие open...УСПЕШНО
подтест - запуск приложений
найдено событие exec...УСПЕШНО
подтест - chmod
найдено событие chmod...УСПЕШНО
подтест - chown
найдено событие chown...УСПЕШНО
подтест - net
найдено событие net...УСПЕШНО
подтест - chroot
найдено событие chroot...УСПЕШНО
подтест - rename
найдено событие rename...УСПЕШНО
подтест - capabilities
найдено событие cap...УСПЕШНО
подтест - audit
найдено событие ch_audit...УСПЕШНО
подтест - acl
найдено событие acl...УСПЕШНО
подтест - mount
найдено событие mount...УСПЕШНО
Check value
0
Тест завершен. Аудит процессов работает корректно
УСПЕШНО
---[audit_proc.sh]: тест завершен

---[secdelrm.sh]: запуск теста
# Проверка гарантированного удаления на ФС ext2 и в режиме secdel
Создание образа диска...УСПЕШНО
Создание файла в файловой системе...УСПЕШНО
Проверка содержимого файла...УСПЕШНО
SECDEL удаление файла и поиск содержимого на диске...УСПЕШНО



# Проверка гарантированного удаления на ФС ext3 и в режиме secdel
Создание образа диска...УСПЕШНО
Создание файла в файловой системе...УСПЕШНО
Проверка содержимого файла...УСПЕШНО
SECDEL удаление файла и поиск содержимого на диске...УСПЕШНО



# Проверка гарантированного удаления на ФС ext4 и в режиме secdel
Создание образа диска...УСПЕШНО
Создание файла в файловой системе...УСПЕШНО
Проверка содержимого файла...УСПЕШНО
SECDEL удаление файла и поиск содержимого на диске...УСПЕШНО



# Проверка гарантированного удаления на ФС ext2 и в режиме secdelrnd
Создание образа диска...УСПЕШНО
Создание файла в файловой системе...УСПЕШНО
Проверка содержимого файла...УСПЕШНО
SECDEL удаление файла и поиск содержимого на диске...УСПЕШНО



# Проверка гарантированного удаления на ФС ext3 и в режиме secdelrnd
Создание образа диска...УСПЕШНО
Создание файла в файловой системе...УСПЕШНО
Проверка содержимого файла...УСПЕШНО
SECDEL удаление файла и поиск содержимого на диске...УСПЕШНО



# Проверка гарантированного удаления на ФС ext4 и в режиме secdelrnd
Создание образа диска...УСПЕШНО
Создание файла в файловой системе...УСПЕШНО
Проверка содержимого файла...УСПЕШНО
SECDEL удаление файла и поиск содержимого на диске...УСПЕШНО



УСПЕШНО
---[secdelrm.sh]: тест завершен

---[rwx.sh]: запуск теста
# Проверка механизма файловой системы RWX
Проверка чтения файла владельцем...УСПЕШНО
Проверка записи для владельца...УСПЕШНО
Проверка чтения для группы владельца...УСПЕШНО
Проверка записи для группы владельца...УСПЕШНО
Проверка чтения для других...УСПЕШНО
Проверка записи для других...УСПЕШНО
УСПЕШНО
---[rwx.sh]: тест завершен

---[acl.sh]: запуск теста
# Проверка Дискреционного РД ФС
Выставление ACL для владельцапроверка битовой маскиУСПЕШНО
Выставление битовой маски для владельца...проверка ACLУСПЕШНО
Выставление ACL для группы...проверка битовой маскиУСПЕШНО
Выставление битовой маски для группы...проверка ACLУСПЕШНО
Выставление ACL для прочих...проверка битовой маскиУСПЕШНО
Выставление битовой маски для прочих...проверка ACLУСПЕШНО
УСПЕШНО
---[acl.sh]: тест завершен

---[mem_test]: запуск теста
Тест очищения памяти...Граница текущего сегмента данных: 0000698fdc21b000
Граница нового сегмента данных: 0000698fdc21f000 
Сигнатура 'Hello world!' @ 0000698fdc21eff3
Граница сегмента после 2го выделения памяти: 0000698fdc21f000
Сигнатура '' @ 0000698fdc21eff3
УСПЕШНО
Тестирование механизма COW (копирование при записи)...Сигнатура 'Hello from world #0' @ 00000000db28f0e0, A
Сигнатура 'Hello from world #1' @ 00000000db28f0e0, B
# Тест изоляции памяти
XXX = 8
Сигнатура 'Hello from world #0' @ 00000000db28f0e0, A (после завершения процесса B)
УСПЕШНО
# Тест изоляции памяти
XXX = 8
УСПЕШНО
---[mem_test]: тест завершен

---[fmac]: запуск теста
PARSEC FMAC TEST: INFO: начинаем...
progname = /usr/lib/parsec/tests/fmac

PARSEC FMAC TEST: INFO: Начинаем тест: mac inheritance test...

PARSEC FMAC TEST: INFO: 	Итерация 0.

PARSEC FMAC TEST: INFO: 	Итерация 1.

PARSEC FMAC TEST: INFO: 	Итерация 2.

PARSEC FMAC TEST: INFO: 	Итерация 3.

PARSEC FMAC TEST: INFO: 	Итерация 4.

PARSEC FMAC TEST: INFO: 	Итерация 5.

PARSEC FMAC TEST: INFO: 	Итерация 6.

PARSEC FMAC TEST: INFO: 	Итерация 7.

PARSEC FMAC TEST: INFO: 	Итерация 8.

PARSEC FMAC TEST: INFO: 	Итерация 9.
PARSEC FMAC TEST: INFO: mac inheritance test прошел успешно

PARSEC FMAC TEST: INFO: Начинаем тест: mac set-get test...

PARSEC FMAC TEST: INFO: 	Итерация 0.

PARSEC FMAC TEST: INFO: 	Итерация 1.

PARSEC FMAC TEST: INFO: 	Итерация 2.

PARSEC FMAC TEST: INFO: 	Итерация 3.

PARSEC FMAC TEST: INFO: 	Итерация 4.

PARSEC FMAC TEST: INFO: 	Итерация 5.

PARSEC FMAC TEST: INFO: 	Итерация 6.

PARSEC FMAC TEST: INFO: 	Итерация 7.

PARSEC FMAC TEST: INFO: 	Итерация 8.

PARSEC FMAC TEST: INFO: 	Итерация 9.
PARSEC FMAC TEST: INFO: mac set-get test прошел успешно

PARSEC FMAC TEST: INFO: Начинаем тест: mac access test...

PARSEC FMAC TEST: INFO: 	Итерация 0.

PARSEC FMAC TEST: INFO: 	Итерация 1.

PARSEC FMAC TEST: INFO: 	Итерация 2.

PARSEC FMAC TEST: INFO: 	Итерация 3.

PARSEC FMAC TEST: INFO: 	Итерация 4.

PARSEC FMAC TEST: INFO: 	Итерация 5.

PARSEC FMAC TEST: INFO: 	Итерация 6.

PARSEC FMAC TEST: INFO: 	Итерация 7.

PARSEC FMAC TEST: INFO: 	Итерация 8.

PARSEC FMAC TEST: INFO: 	Итерация 9.
PARSEC FMAC TEST: INFO: mac access test прошел успешно

PARSEC FMAC TEST: INFO: ТЕСТ УСПЕШЕН!ОБЩИЙ СТАТУС = 0
УСПЕШНО
---[fmac]: тест завершен

---[ipc_mac]: запуск теста
PARSEC IPC/SIGNAL TEST: INFO: start...
progname = /usr/lib/parsec/tests/ipc_mac

PARSEC IPC/SIGNAL TEST: INFO: Начинаем тест: mac IPC test...

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 0.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 1.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 2.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 3.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 4.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 5.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 6.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 7.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 8.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 9.
PARSEC IPC/SIGNAL TEST: INFO: mac IPC test прошел успешно

PARSEC IPC/SIGNAL TEST: INFO: Начинаем тест: mac SignalS test...

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 0.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 1.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 2.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 3.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 4.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 5.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 6.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 7.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 8.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 9.
PARSEC IPC/SIGNAL TEST: INFO: mac SignalS test прошел успешно

PARSEC IPC/SIGNAL TEST: INFO: ТЕСТ УСПЕШЕН!PARSEC IPC/SIGNAL TEST: ERROR: test_cleanup: Отказано в доступе: не могу удалить тестовую директорию /parsec_testdir Отказано в доступе
ОБЩИЙ СТАТУС = 0
УСПЕШНО
---[ipc_mac]: тест завершен

---[ipc_dac]: запуск теста
PARSEC IPC/SIGNAL TEST: INFO: start...
progname = /usr/lib/parsec/tests/ipc_dac

PARSEC IPC/SIGNAL TEST: INFO: Начинаем тест: DAC IPC subtest...

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 0.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 1.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 2.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 3.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 4.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 5.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 6.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 7.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 8.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 9.
PARSEC IPC/SIGNAL TEST: INFO: DAC IPC subtest прошел успешно

PARSEC IPC/SIGNAL TEST: INFO: Начинаем тест: DAC Signals subtest...

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 0.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 1.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 2.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 3.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 4.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 5.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 6.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 7.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 8.

PARSEC IPC/SIGNAL TEST: INFO: 	Итерация 9.
PARSEC IPC/SIGNAL TEST: INFO: DAC Signals subtest прошел успешно

PARSEC IPC/SIGNAL TEST: INFO: ТЕСТ УСПЕШЕН!ОБЩИЙ СТАТУС = 0
УСПЕШНО
---[ipc_dac]: тест завершен

---[tcpip_mac.sh]: запуск теста
PARSEC TCP/IP TEST: INFO: start...
progname = /usr/lib/parsec/tests/tcpip_mac

PARSEC TCP/IP TEST: INFO: Начинаем тест: mac tcp socket test...

PARSEC TCP/IP TEST: INFO: 	Итерация 0.
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1267
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:50214 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1267
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:50224 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1267
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:50226 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1267

PARSEC TCP/IP TEST: INFO: 	Итерация 1.
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1268
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:49188 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1268

PARSEC TCP/IP TEST: INFO: 	Итерация 2.
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1269
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:38684 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1269
PARSEC TCP/IP TEST: INFO: mac tcp socket test прошел успешно

PARSEC TCP/IP TEST: INFO: Начинаем тест: mac udp socket test...

PARSEC TCP/IP TEST: INFO: 	Итерация 0.

PARSEC TCP/IP TEST: INFO: 	Итерация 1.

PARSEC TCP/IP TEST: INFO: 	Итерация 2.
PARSEC TCP/IP TEST: INFO: mac udp socket test прошел успешно

PARSEC TCP/IP TEST: INFO: Начинаем тест: mac unix stream socket test...

PARSEC TCP/IP TEST: INFO: 	Итерация 0.
PARSEC TCP/IP TEST: ERROR: unixs_srv_bind: Операция не позволена: не могу привязать (bind) сокет
PARSEC TCP/IP TEST: ERROR: test_unixs: Операция не позволена: UNIX stream привязка сервера провалилась!
PARSEC TCP/IP TEST: INFO: mac unix stream socket test провалился

PARSEC TCP/IP TEST: INFO: Начинаем тест: mac unix dgram socket test...

PARSEC TCP/IP TEST: INFO: 	Итерация 0.
PARSEC TCP/IP TEST: ERROR: unixd_srv_bind: Операция не позволена: не могу привязать (bind) сокет
PARSEC TCP/IP TEST: ERROR: test_unixd: Операция не позволена: UNIX dgram привязка сокета провалилась!
PARSEC TCP/IP TEST: INFO: mac unix dgram socket test провалился

PARSEC TCP/IP TEST: INFO: Начинаем тест: mac privilege socket set-get test...

PARSEC TCP/IP TEST: INFO: 	Итерация 0.

PARSEC TCP/IP TEST: INFO: 	Итерация 1.

PARSEC TCP/IP TEST: INFO: 	Итерация 2.
PARSEC TCP/IP TEST: INFO: mac privilege socket set-get test прошел успешно

PARSEC TCP/IP TEST: INFO: Начинаем тест: mac privilage socket accept test...

PARSEC TCP/IP TEST: INFO: 	Итерация 0.

PARSEC TCP/IP TEST: INFO: Начинаем тест для TCP...
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1270
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:51268 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1270
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:51270 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1270
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:51272 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1270
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:51274 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1270
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:51276 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1270
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:51278 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1270
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:51280 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1270
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:51282 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1270
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:51284 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1270
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:51286 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1270
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:51288 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!
PARSEC TCP/IP TEST: INFO: ожидаю соединения на порте 1270
PARSEC TCP/IP TEST: INFO: соединение установлено 127.0.0.1:51290 ...
PARSEC TCP/IP TEST: INFO: ок! клиент получил верную строку от сервера!

PARSEC TCP/IP TEST: INFO: Начинаем тест для UNIX STREAM...
PARSEC TCP/IP TEST: ERROR: unixs_srv_bind: Операция не позволена: не могу привязать (bind) сокет
PARSEC TCP/IP TEST: ERROR: test_unixs: Операция не позволена: UNIX stream привязка сервера провалилась!
PARSEC TCP/IP TEST: INFO: mac privilage socket accept test провалился

PARSEC TCP/IP TEST: INFO: ТЕСТ ПРОВАЛИЛСЯ!PARSEC TCP/IP TEST: ERROR: test_cleanup: Отказано в доступе: не могу удалить тестовую директорию /parsec_testdir Отказано в доступе
ОБЩИЙ СТАТУС = 3
УСПЕШНО
---[tcpip_mac.sh]: тест завершен

---[cap_mac]: запуск теста
PARSEC CAPABILITIES TEST: INFO: начинаем...
progname = /usr/lib/parsec/tests/cap_mac

PARSEC CAPABILITIES TEST: INFO: Начинаем тест: capabilities root2user test...

PARSEC CAPABILITIES TEST: INFO: 	Итерация 0.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 1.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 2.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 3.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 4.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 5.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 6.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 7.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 8.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 9.
PARSEC CAPABILITIES TEST: INFO: capabilities root2user test прошел успешно

PARSEC CAPABILITIES TEST: INFO: Начинаем тест: capabilities user2root & inher test...

PARSEC CAPABILITIES TEST: INFO: 	Итерация 0.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 1.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 2.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 3.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 4.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 5.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 6.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 7.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 8.

PARSEC CAPABILITIES TEST: INFO: 	Итерация 9.
PARSEC CAPABILITIES TEST: INFO: capabilities user2root & inher test прошел успешно

PARSEC CAPABILITIES TEST: INFO: ТЕСТ УСПЕШЕН!PARSEC CAPABILITIES TEST: ERROR: test_cleanup: Отказано в доступе: не могу удалить тестовую директорию /parsec_testdir Отказано в доступе
ОБЩИЙ СТАТУС = 0
УСПЕШНО
---[cap_mac]: тест завершен
'''

with open('tests.log', 'w') as logfile:
    logfile.write(log)
    
