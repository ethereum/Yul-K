# Settings
# --------

BUILD_DIR:=.build
DEFN_DIR:=$(BUILD_DIR)/defn
BUILD_LOCAL:=$(CURDIR)/$(BUILD_DIR)/local
LIBRARY_PATH:=$(BUILD_LOCAL)/lib
C_INCLUDE_PATH:=$(BUILD_LOCAL)/include
CPLUS_INCLUDE_PATH:=$(BUILD_LOCAL)/include
PKG_CONFIG_PATH:=$(LIBRARY_PATH)/pkgconfig
export LIBRARY_PATH
export C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH
export PKG_CONFIG_PATH

INSTALL_PREFIX:=/usr/local
INSTALL_DIR?=$(DESTDIR)$(INSTALL_PREFIX)/bin

DEPS_DIR:=deps
eei_submodule:=$(DEPS_DIR)/eei-semantics
evm_submodule:=$(DEPS_DIR)/evm-semantics
K_SUBMODULE:=$(evm_submodule)/deps/k

#PLUGIN_SUBMODULE:=$(abspath $(DEPS_DIR)/plugin)

K_RELEASE:=$(K_SUBMODULE)/k-distribution/target/release/k
K_BIN:=$(K_RELEASE)/bin
K_LIB:=$(K_RELEASE)/lib

PATH:=$(K_BIN):$(PATH)
export PATH

# need relative path for `pandoc` on MacOS
PANDOC_TANGLE_SUBMODULE:=$(evm_submodule)/deps/pandoc-tangle
TANGLER:=$(PANDOC_TANGLE_SUBMODULE)/tangle.lua
LUA_PATH:=$(PANDOC_TANGLE_SUBMODULE)/?.lua;;
export TANGLER
export LUA_PATH

all: build

evm_make:=make --directory $(evm_submodule) DEFN_DIR=../../$(DEFN_DIR)
evm: $(evm_submodule)/make.timestamp

eei_make:=make --directory $(eei_submodule) DEFN_DIR=../../$(DEFN_DIR)
eei_clean:=make --directory $(eei_submodule) clean

evm_files=evm.k data.k
eei_files=eei-driver.k eei.k
evm_source_files:=$(patsubst %, $(evm_submodule)/%, $(patsubst %.k, %.md, $(evm_files)))

eei_source_files:=$(patsubst %, $(eei_submodule)/%, $(patsubst %.k, %.md, $(eei_files)))

$(evm_submodule)/make.timestamp: $(evm_source_files)
	git submodule update --init --recursive
	$(evm_make) deps
	$(evm_make) build-java
	touch $(evm_submodule)/make.timestamp

$(eei_submodule)/make.timestamp: $(eei_source_files)
	git submodule update --init --recursive
	$(eei_make) deps
	$(eei_make) build-java
	touch $(eei_submodule)/make.timestamp


clean:
	rm -rf $(DEFN_DIR)

distclean: clean
	rm -rf $(BUILD_DIR)

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Linux)
  LIBFF_CMAKE_FLAGS=
  LINK_PROCPS=-lprocps
else
  LIBFF_CMAKE_FLAGS=-DWITH_PROCPS=OFF
  LINK_PROCPS=
endif

LIBFF_CC ?=clang-8
LIBFF_CXX?=clang++-8

# K Dependencies
# --------------

all-deps: deps llvm-deps haskell-deps
all-deps: BACKEND_SKIP=
llvm-deps: $(libff_out) deps
llvm-deps: BACKEND_SKIP=-Dhaskell.backend.skip
haskell-deps: deps
haskell-deps: BACKEND_SKIP=-Dllvm.backend.skip
evm-deps: $(evm_submodule)/make.timestamp
eei-deps: $(eei_submodule)/make.timestamp

deps: eei-deps system-deps
system-deps: ocaml-deps
k-deps: $(K_SUBMODULE)/make.timestamp
tangle-deps: $(TANGLER)

BACKEND_SKIP=-Dhaskell.backend.skip -Dllvm.backend.skip

$(K_SUBMODULE)/make.timestamp:
	@echo "== submodule: $@"
	git submodule update --init --recursive -- $(K_SUBMODULE)
	cd $(K_SUBMODULE) && mvn package -DskipTests -U $(BACKEND_SKIP)
	touch $(K_SUBMODULE)/make.timestamp

$(TANGLER):
	@echo "== submodule: $@"
	git submodule update --init -- $(PANDOC_TANGLE_SUBMODULE)

$(PLUGIN_SUBMODULE)/make.timestamp:
	@echo "== submodule: $@"
	git submodule update --init --recursive -- $(PLUGIN_SUBMODULE)
	touch $(PLUGIN_SUBMODULE)/make.timestamp

ocaml-deps:
	eval $$(opam config env) \
	    opam install --yes mlgmp zarith uuidm cryptokit secp256k1.0.3.2 bn128 ocaml-protoc rlp yojson hex ocp-ocamlres

# Building
# --------

MAIN_MODULE:=YULEVM
SYNTAX_MODULE:=YUL-SYNTAX
MAIN_DEFN_FILE:=yulevm
KOMPILE_OPTS:=
LLVM_KOMPILE_OPTS:=

ocaml_kompiled:=$(DEFN_DIR)/ocaml/$(MAIN_DEFN_FILE)-kompiled/interpreter
java_kompiled:=$(DEFN_DIR)/java/$(MAIN_DEFN_FILE)-kompiled/timestamp
node_kompiled:=$(DEFN_DIR)/vm/kevm-vm
haskell_kompiled:=$(DEFN_DIR)/haskell/$(MAIN_DEFN_FILE)-kompiled/definition.kore
llvm_kompiled:=$(DEFN_DIR)/llvm/$(MAIN_DEFN_FILE)-kompiled/interpreter

build: eei-deps build-java
build-ocaml: $(ocaml_kompiled)
build-java: $(java_kompiled)
build-node: $(node_kompiled)
build-haskell: $(haskell_kompiled)
build-llvm: $(llvm_kompiled)

# Tangle definition from *.md files

concrete_tangle:=.k:not(.node):not(.symbolic),.standalone,.concrete
symbolic_tangle:=.k:not(.node):not(.concrete),.standalone,.symbolic

k_files=yulevm.k yul.k
EXTRA_K_FILES+=$(MAIN_DEFN_FILE).k
ALL_K_FILES:=$(k_files) $(EXTRA_K_FILES)

ocaml_files=$(patsubst %, $(DEFN_DIR)/ocaml/%, $(ALL_K_FILES))
llvm_files=$(patsubst %, $(DEFN_DIR)/llvm/%, $(ALL_K_FILES))
java_files=$(patsubst %, $(DEFN_DIR)/java/%, $(ALL_K_FILES))
haskell_files=$(patsubst %, $(DEFN_DIR)/haskell/%, $(ALL_K_FILES))
defn_files=$(ocaml_files) $(llvm_file) $(java_files) $(haskell_files) $(node_files) $(web3_files)

defn: $(defn_files)
ocaml-defn: $(ocaml_files)
llvm-defn: $(llvm_files)
java-defn: $(java_files)
haskell-defn: $(haskell_files)

$(DEFN_DIR)/ocaml/%.k: %.md $(TANGLER)
	@echo "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:"$(concrete_tangle)" $< > $@

$(DEFN_DIR)/llvm/%.k: %.md $(TANGLER)
	@echo "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:"$(concrete_tangle)" $< > $@

$(DEFN_DIR)/java/%.k: %.md $(TANGLER)
	@echo "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:"$(symbolic_tangle)" $< > $@

$(DEFN_DIR)/haskell/%.k: %.md $(TANGLER)
	@echo "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:"$(symbolic_tangle)" $< > $@

# Java Backend

$(java_kompiled): $(java_files)
	@echo "== kompile: $@"
	$(K_BIN)/kompile --debug --main-module $(MAIN_MODULE) --backend java \
	                 --syntax-module $(SYNTAX_MODULE) $(DEFN_DIR)/java/$(MAIN_DEFN_FILE).k \
	                 --directory $(DEFN_DIR)/java -I $(DEFN_DIR)/java \
	                 $(KOMPILE_OPTS)

# Haskell Backend

$(haskell_kompiled): $(haskell_files)
	@echo "== kompile: $@"
	$(K_BIN)/kompile --debug --main-module $(MAIN_MODULE) --backend haskell --hook-namespaces KRYPTO \
	                 --syntax-module $(SYNTAX_MODULE) $(DEFN_DIR)/haskell/$(MAIN_DEFN_FILE).k \
	                 --directory $(DEFN_DIR)/haskell -I $(DEFN_DIR)/haskell \
	                 $(KOMPILE_OPTS)

# OCAML Backend

ifeq ($(BYTE),yes)
  EXT=cmo
  LIBEXT=cma
  DLLEXT=cma
  OCAMLC=c
  LIBFLAG=-a
else
  EXT=cmx
  LIBEXT=cmxa
  DLLEXT=cmxs
  OCAMLC=opt -O3
  LIBFLAG=-shared
endif

$(ocaml_kompiled): $(ocaml_files)
	@echo "== kompile: $@"
	eval $$(opam config env)                              \
	    $(K_BIN)/kompile -O3 --non-strict --backend ocaml \
	    --directory $(ocaml_dir) -I $(ocaml_dir)          \
	    --main-module   $(MAIN_MODULE)                    \
      --syntax-module $(SYNTAX_MODULE) $<


ocaml_dir:=$(DEFN_DIR)/ocaml
#ocaml_defn:=$(patsubst %, $(ocaml_dir)/%, $(_files))


# $(DEFN_DIR)/ocaml/$(MAIN_DEFN_FILE)-kompiled/constants.$(EXT): $(ocaml_files)
# 	@echo "== kompile: $@"
# 	eval $$(opam config env) \
# 	    && $(K_BIN)/kompile --debug --main-module $(MAIN_MODULE) \
# 	                        --syntax-module $(SYNTAX_MODULE) $(DEFN_DIR)/ocaml/$(MAIN_DEFN_FILE).k \
# 	                        --directory $(DEFN_DIR)/ocaml -I $(DEFN_DIR)/ocaml $(KOMPILE_OPTS) \
# 	    && cd $(DEFN_DIR)/ocaml/$(MAIN_DEFN_FILE)-kompiled \
# 	    && ocamlfind $(OCAMLC) -c -g constants.ml -package gmp -package zarith -safe-string

# $(DEFN_DIR)/ocaml/$(MAIN_DEFN_FILE)-kompiled/interpreter: $(DEFN_DIR)/ocaml/$(MAIN_DEFN_FILE)-kompiled/plugin/semantics.$(LIBEXT)
# 	eval $$(opam config env) \
# 	    && cd $(DEFN_DIR)/ocaml/$(MAIN_DEFN_FILE)-kompiled \
# 	        && ocamllex lexer.mll \
# 	        && ocamlyacc parser.mly \
# 	        && ocamlfind $(OCAMLC) -c -g -package gmp -package zarith -package uuidm -safe-string prelude.ml plugin.ml parser.mli parser.ml lexer.ml hooks.ml run.ml -thread \
# 	        && ocamlfind $(OCAMLC) -c -g -w -11-26 -package gmp -package zarith -package uuidm -package ethereum-semantics-plugin-ocaml -safe-string realdef.ml -match-context-rows 2 \
# 	        && ocamlfind $(OCAMLC) $(LIBFLAG) -o realdef.$(DLLEXT) realdef.$(EXT) \
# 	        && ocamlfind $(OCAMLC) -g -o interpreter constants.$(EXT) prelude.$(EXT) plugin.$(EXT) parser.$(EXT) lexer.$(EXT) hooks.$(EXT) run.$(EXT) interpreter.ml \
# 	                               -package gmp -package dynlink -package zarith -package str -package uuidm -package unix -package ethereum-semantics-plugin-ocaml -linkpkg -linkall -thread -safe-string

# LLVM Backend

$(llvm_kompiled): $(llvm_files) $(libff_out)
	@echo "== kompile: $@"
	$(K_BIN)/kompile --debug --main-module $(MAIN_MODULE) --backend llvm \
	                 --syntax-module $(SYNTAX_MODULE) $(DEFN_DIR)/llvm/$(MAIN_DEFN_FILE).k \
	                 --directory $(DEFN_DIR)/llvm -I $(DEFN_DIR)/llvm -I $(DEFN_DIR)/llvm \
	                 --hook-namespaces KRYPTO \
	                 $(KOMPILE_OPTS) \
	                 -ccopt $(PLUGIN_SUBMODULE)/plugin-c/crypto.cpp \
	                 -ccopt -g -ccopt -std=c++11 -ccopt -O2 \
	                 -ccopt -L$(LIBRARY_PATH) \
	                 -ccopt -lff -ccopt -lcryptopp -ccopt -lsecp256k1 $(addprefix -ccopt ,$(LINK_PROCPS))

# Tests
# -----

TEST_CONCRETE_BACKEND:=java
TEST_SYMBOLIC_BACKEND:=java
TEST:=./kyul
CHECK:=git --no-pager diff --no-index --ignore-all-space


tests/%.parse: tests/%
	$(TEST) kast --backend $(TEST_CONCRETE_BACKEND) $< kast > $@-out
	rm -rf $@-out


# Parse Tests

parse_tests:=$(wildcard tests/libyul/yulOptimizerTests/*/*.yul)

test-parse: $(parse_tests:=.parse)
	echo $(parse_tests)

# Sphinx HTML Documentation

# You can set these variables from the command line.
SPHINXOPTS     =
SPHINXBUILD    = sphinx-build
PAPER          =
SPHINXBUILDDIR = $(BUILD_DIR)/sphinx-docs

# Internal variables.
PAPEROPT_a4     = -D latex_paper_size=a4
PAPEROPT_letter = -D latex_paper_size=letter
ALLSPHINXOPTS   = -d ../$(SPHINXBUILDDIR)/doctrees $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) .
# the i18n builder cannot share the environment and doctrees with the others
I18NSPHINXOPTS  = $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) .

sphinx:
	@echo "== media: $@"
	mkdir -p $(SPHINXBUILDDIR) \
	    && cp -r media/sphinx-docs/* $(SPHINXBUILDDIR) \
	    && cp -r *.md $(SPHINXBUILDDIR)/. \
	    && cd $(SPHINXBUILDDIR) \
	    && sed -i 's/{.k[ a-zA-Z.-]*}/k/g' *.md \
	    && $(SPHINXBUILD) -b dirhtml $(ALLSPHINXOPTS) html \
	    && $(SPHINXBUILD) -b text $(ALLSPHINXOPTS) html/text
	@echo "== sphinx: HTML generated in $(SPHINXBUILDDIR)/html, text in $(SPHINXBUILDDIR)/html/text"
