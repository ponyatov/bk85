# var
MODULE = $(notdir $(CURDIR))
module = $(shell echo $(MODULE) | tr A-Z a-z)
OS     = $(shell uname -o|tr / _)
NOW    = $(shell date +%d%m%y)
REL    = $(shell git rev-parse --short=4 HEAD)
BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
CORES  = $(shell grep processor /proc/cpuinfo| wc -l)
PEPS   = E26,E302,E305,E401,E402,E701,E702

# dir
CWD   = $(CURDIR)
TMP   = $(CWD)/tmp
CAR   = $(HOME)/.cargo/bin

# tool
CURL   = curl -L -o
CF     = clang-format
PY     = $(shell which python3)
PIP    = $(shell which pip3)
PEP    = $(shell which autopep8)
RUSTUP = $(CAR)/rustup
CARGO  = $(CAR)/cargo
RUSTC  = $(CAR)/rucstc

# src
P += metaL.py $(MODULE).meta.py
S += $(P) rc
R += $(shell find src -type f -regex ".+.rs$$")
S += $(R) Cargo.toml

# all
.PHONY: all
all: $(R)
	$(CARGO) rustc -- --emit=llvm-ir
	$(MAKE) format

.PHONY: watch
watch:
	$(MAKE) format
	$(MAKE) $@

.PHONY: meta
meta: $(PY) $(MODULE).meta.py
	$^ && $(MAKE) format

# format
.PHONY: format
format: tmp/format_py tmp/format_rs

tmp/format_py: $(P)
	$(PEP) --ignore=$(PEPS) -i $? && touch $@

tmp/format_rs: $(R)
	$(CARGO) fmt && touch $@

# \ rule
$(SRC)/%/README: $(GZ)/%.tar.gz
	cd src ;  zcat $< | tar x && touch $@
$(SRC)/%/README: $(GZ)/%.tar.xz
	cd src ; xzcat $< | tar x && touch $@
# / rule

# doc

.PHONY: doxy
doxy: doxy.gen
	rm -rf docs ; doxygen $< 1>/dev/null

.PHONY: doc
doc:
# / doc

# \ install
.PHONY: install update
install: $(OS)_install doc gz
	$(MAKE) update
update: $(OS)_update
	$(PIP) install --user -U pip autopep8 xxhash
updev:
	$(MAKE) update
	sudo apt install -yu `cat apt.dev`

.PHONY: GNU_Linux_install GNU_Linux_update
GNU_Linux_install GNU_Linux_update:
ifneq (,$(shell which apt))
	sudo apt update
	sudo apt install -u `cat apt.txt`
endif

# \ gz
.PHONY: gz
gz: qucs

QUCS_LINUX ?= Debian_$(shell lsb_release -r|egrep '[0-9]+' -o)
qucs: $(GZ)/qucs-s_$(QUCS_VER)_amd64.deb
	-sudo dpkg -i $<
	sudo apt --fix-broken -y install
$(GZ)/qucs-s_$(QUCS_VER)_amd64.deb:
	$(CURL) $@ http://download.opensuse.org/repositories/home:/ra3xdh/$(QUCS_LINUX)/amd64/qucs-s_$(QUCS_VER)_amd64.deb

# / gz
# / install

# \ merge
MERGE  = Makefile README.md .gitignore apt.dev apt.txt apt.msys doxy.gen $(S)
MERGE += .vscode bin doc lib src tmp

.PHONY: shadow
shadow:
	git push -v
	git checkout $@
	git pull -v

.PHONY: dev
dev:
	git push -v
	git checkout $@
	git pull -v
	git checkout $(SHADOW) -- $(MERGE)

.PHONY: release
release:
	git tag $(NOW)-$(REL)
	git push -v --tags
	$(MAKE) shadow

.PHONY: zip
ZIP = $(TMP)/$(MODULE)_$(BRANCH)_$(NOW)_$(REL).src.zip
zip:
	git archive --format zip --output $(ZIP) HEAD
	$(MAKE) doxy ; zip -r $(ZIP) docs
# / merge
