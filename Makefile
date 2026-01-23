build: 
	bashly generate --upgrade

install:
	cp target/lct /usr/local/bin/lct

uninstall:
	rm -f /usr/local/bin/lct


