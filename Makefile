all:
	# Установка бита исполнения для исполняемых файлов
	find root -type f -exec file {} \; | grep executable | cut -d':' -f1 | xargs chmod +x
	cd root
	# Установка владельца root:root для каталогов и файлов в архиве
	tar --owner=root --group=root -czvf postinst.tar.gz *
clean:
	rm postinst.tar.gz
