.PHONY: clean test build kubetemplates

export TARGET:=target

all: kubetemplates

clean:
	$(RM) -rf ${TARGET}
	$(RM) -rf test/${TARGET}
	$(RM) -rf test/sample-app/charts/*

test:
	cp ${TARGET}/* test/sample-app/charts/
	helm package -d test/${TARGET} test/sample-app
	helm template --debug test/${TARGET}/sample-app-*.tgz

build: clean
	mkdir ${TARGET}
	helm lint kubetemplates
	helm package -d ${TARGET} kubetemplates

kubetemplates: build test
