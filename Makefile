# How to use this makefile
# 
# To compile and create the pkg using the default PROFILE and ARCH.
# > make 
#
# Remove build outputs for the default PROFILE and ARCH.
# > make clean
#
# Copy the pkg file to the packages folder
# > make install
#
# To cross-compile for the ER-301 hardware, add ARCH=am335x the above examples.
#
# To create a release version for the am335x:
# make PROFILE=release ARCH=am335x
#
# Remove build outputs for all profiles and architectures.
# > make dist-clean
#
# WARNING: In order to keep this makefile simple, dependencies are hard-coded 
# rather than auto-generated.

# Override these defaults on the commandline:
PKGNAME ?= Accents
PKGVERSION ?= 0.6.14
LIBNAME ?= libAccents
ARCH ?= linux
PROFILE ?= testing
SDKPATH ?= ../er-301

# Describe your files to this makefile:
headers = VoltageVault.h Maths.h PointsEG.h Bitwise.h
sources = VoltageVault.cpp Accents.cpp.swig Maths.cpp PointsEG.cpp Bitwise.cpp
assets = toc.lua  Ringmod.lua ABSwitch.lua Amie.lua BespokeAliasingPulse.lua BespokeBPF.lua Bitwise.lua CarouselClockDivider.lua ClockedRandomGate.lua Compare.lua Flanger.lua LinearSamplingVCA.lua Logics.lua MathsUnit.lua MotionSensor.lua OctaveCVShifter.lua Phaser4.lua PingableScaledRandom.lua PointsEG.lua RotarySpeakerSim.lua Scorpio.lua StereoEnsemble.lua TimedGate.lua VoltageBank.lua VoltageBank4.lua VoltageBank2.lua VoltageVault.lua WeightedCoinToss.lua XFade.lua Xo.lua Xoxo.lua Xoxoxo.lua Xxxxxx.lua assets/*

includes = .

# Do you need any additional preprocess symbols?
symbols = 

#######################################################
# Edits are generally not needed beyond this point.

out_dir = $(PROFILE)/$(ARCH)
lib_file = $(out_dir)/$(LIBNAME).so
package_file = $(out_dir)/$(PKGNAME)-$(PKGVERSION).pkg

swig_interface = $(filter %.cpp.swig,$(sources))
swig_wrapper = $(addprefix $(out_dir)/,$(swig_interface:%.cpp.swig=%_swig.cpp))
swig_object = $(swig_wrapper:%.cpp=%.o)

c_sources = $(filter %.c,$(sources))
cpp_sources = $(filter %.cpp,$(sources))

objects = $(addprefix $(out_dir)/,$(c_sources:%.c=%.o))
objects += $(addprefix $(out_dir)/,$(cpp_sources:%.cpp=%.o))
objects += $(swig_object)

# includes += $(SDKPATH) $(SDKPATH)/arch/$(ARCH)
includes += $(SDKPATH) $(SDKPATH)/arch/$(ARCH) $(SDKPATH)/emu

ifeq ($(ARCH),am335x)
INSTALLPATH.am335x = /media/$(USERNAME)/FRONT/ER-301/packages
CFLAGS.am335x = -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=hard -mabi=aapcs -Dfar= -D__DYNAMIC_REENT__ 
LFLAGS = -nostdlib -nodefaultlibs -r
include $(SDKPATH)/scripts/am335x.mk
endif

ifeq ($(ARCH),linux)
INSTALLPATH.linux = $(HOME)/.od/rear
CFLAGS.linux = -Wno-deprecated-declarations -msse4 -fPIC
LFLAGS = -shared
include $(SDKPATH)/scripts/linux.mk
endif

CFLAGS.common = -Wall -ffunction-sections -fdata-sections
CFLAGS.speed = -O3 -ftree-vectorize -ffast-math
CFLAGS.size = -Os

CFLAGS.release = $(CFLAGS.speed) -Wno-unused
CFLAGS.testing = $(CFLAGS.speed) -DBUILDOPT_TESTING
CFLAGS.debug = -g -DBUILDOPT_TESTING

CFLAGS += $(CFLAGS.common) $(CFLAGS.$(ARCH)) $(CFLAGS.$(PROFILE))
CFLAGS += $(addprefix -I,$(includes)) 
CFLAGS += $(addprefix -D,$(symbols))

# swig-specific flags
SWIGFLAGS = -lua -no-old-metatable-bindings -nomoduleglobal -small -fvirtual
SWIGFLAGS += $(addprefix -I,$(includes)) 
CFLAGS.swig = $(CFLAGS.common) $(CFLAGS.$(ARCH)) $(CFLAGS.size)
CFLAGS.swig += $(addprefix -I,$(includes)) -I$(SDKPATH)/libs/lua54
CFLAGS.swig += $(addprefix -D,$(symbols))

#######################################################
# Rules

all: $(package_file)

$(swig_wrapper): $(headers) Makefile

$(objects): $(headers) Makefile

$(lib_file): $(objects)
	@echo [LINK $@]
	@$(CC) $(CFLAGS) -o $@ $(objects) $(LFLAGS)

$(package_file): $(lib_file) $(assets)
	@echo [ZIP $@]
	@rm -f $@
	@$(ZIP) -j $@ $(lib_file) $(assets)

list: $(package_file)
	@unzip -l $(package_file)

clean:
	rm -rf $(out_dir)

dist-clean:
	rm -rf testing release debug

install: $(package_file)
	cp $(package_file) $(INSTALLPATH.$(ARCH))

# C/C++ compilation rules

$(out_dir)/%.o: %.c
	@echo [C $<]
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) -std=gnu11 -c $< -o $@

$(out_dir)/%.o: %.cpp
	@echo [C++ $<]
	@mkdir -p $(@D)
	@$(CPP) $(CFLAGS) -std=gnu++11 -c $< -o $@

# SWIG wrapper rules

.PRECIOUS: $(out_dir)/%_swig.c $(out_dir)/%_swig.cpp

$(out_dir)/%_swig.cpp: %.cpp.swig
	@echo [SWIG $<]
	@mkdir -p $(@D)
	@$(SWIG) -fvirtual -fcompact -c++ $(SWIGFLAGS) -o $@ $<

$(out_dir)/%_swig.o: $(out_dir)/%_swig.cpp
	@echo [C++ $<]
	@mkdir -p $(@D)
	@$(CPP) $(CFLAGS.swig) -std=gnu++11 -c $< -o $@

