-include Makefile.config

BASE_TESTS = \
  tutorial/noop \
  tutorial/noop-functor \
  tutorial/hello \
  tutorial/hello-key \
  tutorial/lwt/echo_server \
  tutorial/lwt/heads1 \
  tutorial/lwt/heads2 \
  tutorial/lwt/timeout1 \
  tutorial/lwt/timeout2 \
  device-usage/clock \
  device-usage/conduit_server \
  device-usage/console \
  device-usage/kv_ro \
  device-usage/network \
  device-usage/ping6 \
  device-usage/prng \
  applications/dhcp \
  applications/dns \
  applications/static_website_tls

ifeq ($(MODE),muen)
	TESTS = $(BASE_TESTS)
else
	TESTS = $(BASE_TESTS)
	TESTS += device-usage/block
endif

ifdef WITH_TRACING
TESTS += device-usage/tracing
endif

CONFIGS = $(patsubst %, %-configure, $(TESTS))
BUILDS  = $(patsubst %, %-build,     $(TESTS))
TESTRUN = $(patsubst %, %-testrun,   $(TESTS))
CLEANS  = $(patsubst %, %-clean,     $(TESTS))

all: build

configure: $(CONFIGS)
build: $(BUILDS)
testrun: $(TESTRUN)
clean: $(CLEANS)

## default tests
%-configure:
	cd $* && $(MIRAGE) configure -t $(MODE) $(MIRAGE_FLAGS)


OVERLAY_REMOTE="git+https://github.com/dune-universe/opam-overlays.git#master"

%-duniverse: %-configure
	cd $* && duniverse init --overlay-remote=$(OVERLAY_REMOTE)
	cd $* && duniverse opam-install -y
	cd $* && duniverse pull -y
	cd $* && dune upgrade
	mv $(wildcard $*/*.opam) $*/mirage-unikernel.opam
	opam pin add -k path --no-action --yes mirage-unikernel $*
	opam depext --yes --update mirage-unikernel
	opam pin remove --no-action mirage-unikernel
	rm $*/mirage-unikernel.opam

%-build: %-duniverse
	-cp Makefile.user $*
	cd $* && $(MAKE)

%-clean:
	-cd $* && $(MAKE) clean
	-$(RM) $*/Makefile.user

%-testrun:
	$(SUDO) sh ./testrun.sh $*
