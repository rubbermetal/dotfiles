###############################################################################
# Makefile — Compile Conky helper scripts (C versions)
#
# Usage:
#   make              Build all scripts (skips those needing missing libs)
#   make all          Same as above
#   make install      Copy binaries to ../  (the C/ directory)
#   make clean        Remove compiled binaries
#   make check        Test that compiled binaries run
#
# Works on: x86-64, arm64, armhf (any Linux with gcc or cc)
###############################################################################

CC       ?= cc
CFLAGS   ?= -O2 -Wall
OUTDIR   := ..
SRCDIR   := .

# --- Detect available libraries ---
HAS_CURL := $(shell echo 'int main(){}' | $(CC) -x c - -lcurl -o /dev/null 2>/dev/null && echo yes)
HAS_MATH := $(shell echo 'int main(){}' | $(CC) -x c - -lm -o /dev/null 2>/dev/null && echo yes)

# --- Core targets (no external libs needed) ---
CORE_TARGETS := \
	battery_condition \
	battery_status \
	core_temps \
	freemem \
	freeswap \
	interfacedownspeed \
	interfaceupspeed \
	lan \
	totalmem \
	totalswap \
	usedmem \
	wireless-essid

# --- Targets needing libm ---
MATH_TARGETS :=
ifeq ($(HAS_MATH),yes)
MATH_TARGETS += moon_phase usedswap
endif

# --- Targets needing libcurl ---
CURL_TARGETS :=
ifeq ($(HAS_CURL),yes)
CURL_TARGETS += wan weather
endif

ALL_TARGETS := $(CORE_TARGETS) $(MATH_TARGETS) $(CURL_TARGETS)

.PHONY: all install clean check

all: $(ALL_TARGETS)
	@echo ""
	@echo "Built: $(ALL_TARGETS)"
ifneq ($(HAS_MATH),yes)
	@echo "Skipped (libm not found): moon_phase usedswap"
endif
ifneq ($(HAS_CURL),yes)
	@echo "Skipped (libcurl not found): wan weather"
endif

# --- Core builds ---
battery_condition: battery_condition.c
	$(CC) $(CFLAGS) -o $@ $<

battery_status: battery_status.c
	$(CC) $(CFLAGS) -o $@ $<

core_temps: core_temps.c
	$(CC) $(CFLAGS) -o $@ $<

freemem: freemem.c
	$(CC) $(CFLAGS) -o $@ $<

freeswap: freeswap.c
	$(CC) $(CFLAGS) -o $@ $<

interfacedownspeed: interfacedownspeed.c
	$(CC) $(CFLAGS) -o $@ $<

interfaceupspeed: interfaceupspeed.c
	$(CC) $(CFLAGS) -o $@ $<

lan: lan.c
	$(CC) $(CFLAGS) -o $@ $<

totalmem: totalmem.c
	$(CC) $(CFLAGS) -o $@ $<

totalswap: totalswap.c
	$(CC) $(CFLAGS) -o $@ $<

usedmem: usedmem.c
	$(CC) $(CFLAGS) -o $@ $<

wireless-essid: wireless-essid.c
	$(CC) $(CFLAGS) -o $@ $<

# --- Math builds ---
moon_phase: moon_phase.c
	$(CC) $(CFLAGS) -o $@ $< -lm

usedswap: usedswap.c
	$(CC) $(CFLAGS) -o $@ $< -lm

# --- Curl builds ---
wan: wan.c
	$(CC) $(CFLAGS) -o $@ $< -lcurl

weather: weather.c
	$(CC) $(CFLAGS) -o $@ $< -lcurl

# --- Install: copy binaries up to C/ directory ---
install: all
	@for bin in $(ALL_TARGETS); do \
		cp "$$bin" "$(OUTDIR)/$$bin"; \
		echo "  installed: $(OUTDIR)/$$bin"; \
	done

# --- Clean ---
clean:
	rm -f $(CORE_TARGETS) moon_phase usedswap wan weather

# --- Quick sanity check ---
check: all
	@echo "Running quick checks..."
	@for bin in $(ALL_TARGETS); do \
		if [ -x "./$$bin" ]; then \
			printf "  %-25s" "$$bin"; \
			if ./$$bin >/dev/null 2>&1; then \
				echo "OK"; \
			else \
				echo "FAIL (exit $$?)"; \
			fi; \
		fi; \
	done
