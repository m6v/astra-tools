ping:
	ansible all -m ping -i hosts
install:
	ansible-playbook postinstall.yml -i hosts --ask-become-pass
arch:
	# Установка бита исполнения для исполняемых файлов
	find root -type f -exec file {} \; | grep executable | cut -d':' -f1 | xargs chmod +x
	# Смену каталога и архивирование делать обязательно в одной строке, иначе make возвращается в текущий каталог
	cd root; tar --exclude="DEBIAN" --exclude="*.bak" --owner=root --group=root -czvf ../postinst.tar.gz *
	# Sed убирает символ . в начале путей файла с контр. суммами
	cd root; find -type f -not -path "*DEBIAN*" -exec md5sum '{}' \; | sed -e 's/.\//\//' > ../postinst.md5
deb:
	dpkg-deb --root-owner-group -Z xz --build root
clean:
	rm postinst.tar.gz
