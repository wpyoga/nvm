SPLIT_SCRIPTS = \
	nvm-split.sh \
	src/main-commands/*.sh \
	src/functions/*.sh \

all: nvm-merged.sh

nvm-merged.sh: $(SPLIT_SCRIPTS)
	merge-shell.sh nvm-split.sh > nvm-merged.sh

test: nvm-merged.sh
	@diff -u nvm.sh nvm-merged.sh
	@echo "Test passed"

clean:
	rm -f nvm-merged.sh
