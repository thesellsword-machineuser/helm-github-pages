.PHONY: kubetemplates

export TARGET:=target

all: kubetemplates

clean:
	$(RM) -rf ${TARGET}

kubetemplates: clean
	mkdir ${TARGET}
	helm lint kubetemplates
	helm package -d ${TARGET} kubetemplates
