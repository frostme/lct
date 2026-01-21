build: 
	bashly generate -q

install: build
	cp lct /usr/local/bin/lct

uninstall:
	rm -f /usr/local/bin/lct


