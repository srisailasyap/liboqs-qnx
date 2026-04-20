ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

include $(MKFILES_ROOT)/qmacros.mk

NAME=liboqs

QNX_PROJECT_ROOT ?= $(PRODUCT_ROOT)/../../$(NAME)

INSTALL_ROOT ?= $(INSTALL_ROOT_$(OS))
PREFIX ?= /usr/local
CMAKE_BUILD_TYPE ?= Release

ALL_DEPENDENCIES = $(NAME)_all
.PHONY: $(NAME)_all install check clean

CFLAGS += $(FLAGS)
LDFLAGS += -Wl,--build-id=md5

include $(MKFILES_ROOT)/qtargets.mk

BUILD_TESTING ?= OFF

CMAKE_FIND_ROOT_PATH := $(QNX_TARGET);$(QNX_TARGET)/$(CPUVARDIR);$(INSTALL_ROOT)/$(CPUVARDIR)
CMAKE_MODULE_PATH := $(QNX_TARGET)/$(CPUVARDIR)/$(PREFIX)/lib/cmake;$(INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)/lib/cmake

CFLAGS += -I$(INSTALL_ROOT)/$(PREFIX)/include -I$(INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)/include

CMAKE_ARGS = -DCMAKE_TOOLCHAIN_FILE=$(PROJECT_ROOT)/qnx.nto.toolchain.cmake \
             -DCMAKE_SYSTEM_PROCESSOR=$(CPUVARDIR) \
             -DCMAKE_INSTALL_PREFIX="$(INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)" \
             -DCMAKE_STAGING_PREFIX="$(INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)" \
             -DCMAKE_INSTALL_INCLUDEDIR="$(INSTALL_ROOT)/$(PREFIX)/include" \
             -DCMAKE_MODULE_PATH="$(CMAKE_MODULE_PATH)" \
             -DCMAKE_FIND_ROOT_PATH="$(CMAKE_FIND_ROOT_PATH)" \
             -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
             -DBUILD_SHARED_LIBS=ON \
             -DOQS_BUILD_ONLY_LIB=OFF \
             -DOQS_DIST_BUILD=OFF \
             -DOQS_USE_OPENSSL=OFF \
             -DOQS_USE_PTHREADS=ON \
             -DOQS_PERMIT_UNSUPPORTED_ARCHITECTURE=ON \
             -DCMAKE_C_USE_RESPONSE_FILE_FOR_OBJECTS=OFF

MAKE_ARGS ?= -j $(firstword $(JLEVEL) 1)

$(NAME)_all:
	@mkdir -p build
	@cd build && cmake $(CMAKE_ARGS) $(QNX_PROJECT_ROOT)
	@cd build && make VERBOSE=1 all $(MAKE_ARGS)

install check: $(NAME)_all
	@echo Installing...
	@cd build && make VERBOSE=1 install $(MAKE_ARGS)
	@echo Done.

clean iclean spotless:
	rm -rf build

uninstall:
