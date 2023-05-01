all:
	mkdocs build --clean

dev:
	sudo apt install mkdocs
	pip install mkdocs-material
