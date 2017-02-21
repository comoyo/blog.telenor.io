.PHONY: setup
setup:
	bundle install

.PHONY: serve
serve:
	bundle exec jekyll serve
