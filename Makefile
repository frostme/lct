build: 
	bashly generate

install:
	cp target/lct /usr/local/bin/lct

uninstall:
	rm -f /usr/local/bin/lct


