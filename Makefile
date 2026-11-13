.PHONY: all app run clean

all: app

app:
	@chmod +x build_app.sh
	@./build_app.sh

run: app
	@echo "Lancio di UniFlow.app..."
	@open build/UniFlow.app

clean:
	@rm -rf build
	@echo "Directory build rimossa."
