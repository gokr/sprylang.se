all:
	mkdocs build --clean

clean:
	rm -rf docs

dev:
	sudo apt install mkdocs
	pip install mkdocs-material
