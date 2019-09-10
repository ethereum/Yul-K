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

DEPS_DIR:=./deps
K_SUBMODULE:=$(DEPS_DIR)/k

#PLUGIN_SUBMODULE:=$(abspath $(DEPS_DIR)/plugin)

K_RELEASE:=$(K_SUBMODULE)/k-distribution/target/release/k
K_BIN:=$(K_RELEASE)/bin
K_LIB:=$(K_RELEASE)/lib

PATH:=$(K_BIN):$(PATH)
export PATH

# need relative path for `pandoc` on MacOS
PANDOC_TANGLE_SUBMODULE:=$(DEPS_DIR)/pandoc-tangle
TANGLER:=$(PANDOC_TANGLE_SUBMODULE)/tangle.lua
LUA_PATH:=$(PANDOC_TANGLE_SUBMODULE)/?.lua;;
export TANGLER
export LUA_PATH

all: build

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

deps: k-deps tangle-deps
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
haskell_kompiled:=$(DEFN_DIR)/haskell/$(MAIN_DEFN_FILE)-kompiled/definition.kore
llvm_kompiled:=$(DEFN_DIR)/llvm/$(MAIN_DEFN_FILE)-kompiled/interpreter

build: deps build-java
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
java-defn: $(java_files)

$(DEFN_DIR)/ocaml/%.k: %.md $(TANGLER)
	@echo "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:"$(concrete_tangle)" $< > $@

$(DEFN_DIR)/java/%.k: %.md $(TANGLER)
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

# Haskell Backend (not supported)

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



# LLVM Backend (not supported)

# Tests
# -----

TEST_CONCRETE_BACKEND:=java
TEST_SYMBOLIC_BACKEND:=java
TEST:=./kyul
CHECK:=git --no-pager diff --no-index --ignore-all-space


tests/%.parse: tests/%
	$(TEST) kast --backend $(TEST_CONCRETE_BACKEND) $< kast > $@-out
	rm -rf $@-out

tests/%.run: tests/%
	$(TEST) run --backend $(TEST_CONCRETE_BACKEND) $< > $@-out
	rm -rf $@-out

# The files in the disambiguator repo uses a different dialect
wasm-dialect:=$(wildcard tests/libyul/yulOptimizerTests/disambiguator/*.yul) tests/libyul/yulOptimizerTests/expressionInliner/simple.yul tests/libyul/yulOptimizerTests/expressionInliner/with_args.yul

failing_tests=tests/libyul/yulOptimizerTests/abi2.yul

# Parse Tests
interpreter_tests:=$(wildcard tests/libyul/yulInterpreterTests/*.yul)
optimizer_tests:=$(filter-out $(wasm-dialect) $(failing_tests), $(wildcard tests/libyul/yulOptimizerTests/*/*.yul))

test-parse: $(optimizer_tests:=.parse)

test-run: $(interpreter_tests:=.run)
