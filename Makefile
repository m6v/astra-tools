all:
	# Установка бита исполнения для исполняемых файлов
	find root -type f -exec file {} \; | grep executable | cut -d':' -f1 | xargs chmod +x
	# Установка владельца root:root для каталогов и файлов в архиве
	# Смена каталога и архивирование в одной строке, иначе make возвращается в текущий каталог
	cd root; tar --owner=root --group=root -czvf ../postinst.tar.gz *
clean:
	rm postinst.tar.gz
