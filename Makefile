install:
	npm install -g @vscode/vsce

build:
	vsce package

publish:
	vsce publish

xccolortheme:
	sh scripts/install_xccolortheme.sh
