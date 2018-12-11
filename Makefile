
#!make
include .env
export $(shell sed 's/=.*//' .env)

.PHONY= pdf gitbook update-bib update-csl clear get-output-name mkdir-template download-impress-components download-revealjs-components create-doc

output-name:= $(shell grep "title: " $(PDF_CONFIG) | sed -e "s/title: //" |sed -e "s/\s/-/g" | tr [A-Z] [a-z])

build-all : pdf presentation gitbook

update-bib: mkdir-bib
ifeq (,$(wildcard  $(BIBLIOGRAPHY)))
	echo "updating bib file (force)"
	@curl -s --header "Zotero-API-Key:$(Z_API_KEY)" https://api.zotero.org/users/$(Z_USER_ID)/collections/$(Z_COLLECTION)/items?format=biblatex -o $(BIBLIOGRAPHY) --connect-timeout 10
endif

update-bib-force: mkdir-bib
	echo "updating bib file (force)"
	@curl -s --header "Zotero-API-Key:$(Z_API_KEY)" https://api.zotero.org/users/$(Z_USER_ID)/collections/$(Z_COLLECTION)/items?format=biblatex -o $(BIBLIOGRAPHY) --connect-timeout 10


update-csl: mkdir-bib
ifeq (,$(wildcard $(CSL_FILE)))
	echo "updating csl file"
	@curl -s $(CSL_URL) -o $(CSL_FILE)
endif

update-csl-force: mkdir-bib
	echo "updating csl file (force)"
	@curl -s $(CSL_URL) -o $(CSL_FILE)

pdf: mkdir-pdf update-bib update-csl
	pandoc --toc -N -s $(MD_SRC)*.md $(PDF_CONFIG) -o $(PDF_DIR)$(output-name).pdf --filter pandoc-citeproc

download-revealjs-components: mkdir-presentation
ifeq (,$(wildcard  presentation/master.tar.gz))
	curl -s -L https://github.com/hakimel/reveal.js/archive/master.tar.gz > $(PRESENTATION_DIR)master.tar.gz
	rm -f -r $(PRESENTATION_DIR)reveal.js
	tar -xzvf $(PRESENTATION_DIR)master.tar.gz -C $(PRESENTATION_DIR)
	mv $(PRESENTATION_DIR)reveal.js-master $(PRESENTATION_DIR)reveal.js
endif

md-pretify:
	./.script/md_pretify.sh

gitbook: update-bib update-csl
	echo "making gitbook"
	gitbook install
	./.script/create-git-book.sh
	gitbook build

serve-doc:
	gitbook serve

presentation: download-revealjs-components update-bib update-csl
		echo "making presentation"
	pandoc -t revealjs -s -o $(PRESENTATION_DIR)$(output-name)_slides.html $(PRESENTATION_SRC)*.md $(PDF_CONFIG) -V revealjs-url=./reveal.js --filter pandoc-citeproc

mkdir-pdf:
	@mkdir -p $(PDF_DIR)

mkdir-bib:
	@mkdir -p `dirname $(BIBLIOGRAPHY)`

mkdir-presentation:
	@mkdir -p $(PRESENTATION_DIR)

clear:
	@rm -f -r `dirname $(BIBLIOGRAPHY)`
	@rm -f -r $(GIT_BOOK_DIR)
	@rm -f book.json
	@rm -f -r _book/
	@rm -f -r $(PDF_DIR)
	@rm -f -r $(PRESENTATION_DIR)
