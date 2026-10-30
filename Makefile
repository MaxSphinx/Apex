.PHONY: all build release app dmg run clean install

all: app

build:
	SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk swift build

release:
	SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk swift build -c release

app:
	chmod +x build.sh
	./build.sh

dmg: app

run:
	@if [ -d "build/Apex.app" ]; then \
		open build/Apex.app; \
	else \
		SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk swift run Apex; \
	fi

install: app
	@echo "==> Installing Apex to /Applications..."
	@rm -rf /Applications/Apex.app
	@cp -R build/Apex.app /Applications/
	@echo "==> Apex installed in /Applications. Launching..."
	@open /Applications/Apex.app

clean:
	rm -rf .build build
