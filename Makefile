build: 
	bashly generate --upgrade

validate:
	bashly validate

docs:
	bashly render :markdown_github docs
	git add docs
	git commit -m "Update documentation"
	@git push origin main

release: build validate docs
	./release.sh

install:
	cp target/build/lct /usr/local/bin/lct

uninstall:
	rm -f /usr/local/bin/lct


