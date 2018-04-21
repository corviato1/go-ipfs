TGT_BIN :=
CLEAN :=
COVERAGE :=
DISTCLEAN :=
TEST :=
TEST_SHORT :=

all: help    # all has to be first defined target
.PHONY: all

include mk/git.mk # has to be before tarball.mk
include mk/tarball.mk
include mk/util.mk
include mk/golang.mk
include mk/gx.mk

# -------------------- #
#   extra properties   #
# -------------------- #

ifeq ($(TEST_NO_FUSE),1)
	GOTAGS += nofuse
endif
export IPFS_REUSEPORT=false

# -------------------- #
#       sub-files      #
# -------------------- #
dir := bin
include $(dir)/Rules.mk

# tests need access to rules from plugin
dir := plugin
include $(dir)/Rules.mk

dir := test
include $(dir)/Rules.mk

dir := cmd/ipfs
include $(dir)/Rules.mk

# include this file only if coverage target is executed
# it is quite expensive
ifneq ($(filter coverage% clean distclean,$(MAKECMDGOALS)),)
	# has to be after cmd/ipfs due to PATH
	dir := coverage
	include $(dir)/Rules.mk
endif

dir := namesys/pb
include $(dir)/Rules.mk

dir := unixfs/pb
include $(dir)/Rules.mk

dir := exchange/bitswap/message/pb
include $(dir)/Rules.mk

dir := pin/internal/pb
include $(dir)/Rules.mk


# -------------------- #
#   universal rules    #
# -------------------- #

%.pb.go: %.proto
	$(PROTOC)

# -------------------- #
#     core targets     #
# -------------------- #

build: $(TGT_BIN)
.PHONY: build

clean:
	rm -rf $(CLEAN)
.PHONY: clean

coverage: $(COVERAGE)
.PHONY: coverage

distclean: clean
	rm -rf $(DISTCLEAN)
	git clean -ffxd
.PHONY: distclean

test: $(TEST)
.PHONY: test

test_short: $(TEST_SHORT)
.PHONY: test_short

deps: gx-deps
.PHONY: deps

nofuse: GOTAGS += nofuse
nofuse: build
.PHONY: nofuse

install: cmd/ipfs-install
.PHONY: install

install_unsupported:
	@echo "note: this command has yet to be tested to build in the system you are using"
	@echo "installing gx"
	go get -v -u github.com/whyrusleeping/gx
	go get -v -u github.com/whyrusleeping/gx-go
	@echo check gx and gx-go
	gx -v && gx-go -v
	@echo downloading dependencies
	gx install --global
	@echo "installing go-ipfs"
	go install -v -tags nofuse ./cmd/ipfs
.PHONY: install_unsupported

uninstall:
	go clean -i ./cmd/ipfs
.PHONY: uninstall

help:
	@echo 'DEPENDENCY TARGETS:'
	@echo ''
	@echo '  deps                 - Download dependencies using bundled gx'
	@echo '  test_sharness_deps   - Download and build dependencies for sharness'
	@echo ''
	@echo 'BUILD TARGETS:'
	@echo ''
	@echo '  all          - print this help message'
	@echo '  build        - Build binary at ./cmd/ipfs/ipfs'
	@echo '  nofuse       - Build binary with no fuse support'
	@echo '  install      - Build binary and install into $$GOPATH/bin'
#	@echo '  dist_install - TODO: c.f. ./cmd/ipfs/dist/README.md'
	@echo ''
	@echo 'CLEANING TARGETS:'
	@echo ''
	@echo '  clean        - Remove files generated by build'
	@echo '  distclean    - Remove files that are no part of a repository'
	@echo '  uninstall    - Remove binary from $$GOPATH/bin'
	@echo ''
	@echo 'TESTING TARGETS:'
	@echo ''
	@echo '  test                    - Run all tests'
	@echo '  test_short              - Run short go tests and short sharness tests'
	@echo '  test_go_short           - Run short go tests'
	@echo '  test_go_test            - Run all go tests'
	@echo '  test_go_expensive       - Run all go tests and compile on all platforms'
	@echo '  test_go_race            - Run go tests with the race detector enabled'
	@echo '  test_go_megacheck       - Run the `megacheck` vetting tool'
	@echo '  test_sharness_short     - Run short sharness tests'
	@echo '  test_sharness_expensive - Run all sharness tests'
	@echo '  coverage     - Collects coverage info from unit tests and sharness'
	@echo
.PHONY: help
