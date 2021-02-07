
# Configuration

VERSION_NAME := 20210121
VERSION_TARGET := aarch64-linux-android
VERSION_ARCH := aarch64

BUILD_DIR := $(PWD)

TARGET_CC := $(VERSION_TARGET)-gcc
TARGET_CXX := $(VERSION_TARGET)-g++

OPTIMIZE_CFLAGS := -O2
ifeq (x$(VERSION_ARCH), xarm)
OPTIMIZE_CFLAGS += -march=armv7-a -mthumb -mfpu=neon -mfloat-abi=softfp
else

endif

WERROR_CFLAGS := 

COMMON_CFLAGS := $(OPTIMIZE_CFLAGS) $(WERROR_CFLAGS) -g

LWJGL2_ANT_FLAGS := -Dbuild.32bit.only=true
ifeq (x$(VERSION_ARCH), xaarch64)
LWJGL2_ANT_FLAGS := -Dbuild.64bit.only=true
endif


LWJGL2_NATIVE_LIB := liblwjgl.so
ifeq (x$(VERSION_ARCH), xaarch64)
LWJGL2_NATIVE_LIB := liblwjgl64.so
endif

LWJGL3_TARGET_ARCH := arm32
ifeq (x$(VERSION_ARCH), xaarch64)
LWJGL3_TARGET_ARCH := arm64
endif

JDK_ARCH := aarch32
ifeq (x$(VERSION_ARCH), xaarch64)
JDK_ARCH := aarch64
endif

JDK_VM_VARIANT := client
ifeq (x$(VERSION_ARCH), xaarch64)
JDK_VM_VARIANT := server
endif


PROJECT_ROOT := /home/cosine/projects
J2RE_IMAGE := /home/cosine/projects/openjdk-jdk8u-aarch64-8u272/openjdk-jdk8u-aarch64-android/build/linux-aarch64-normal-server-release/images/j2re-image
JDK_INCLUDE := /home/cosine/projects/openjdk-jdk8u-aarch64-8u272/openjdk-jdk8u-aarch64-android/build/linux-aarch64-normal-server-release/images/j2sdk-image/include
BOAT := $(PROJECT_ROOT)/Boat-4
BOAT_INCLUDE := $(BOAT)/jni/boat/include
BOAT_LIB := $(BUILD_DIR)/boat
LWJGL2 := $(PROJECT_ROOT)/lwjgl-boat
GL4ES := $(PROJECT_ROOT)/gl4es
OPENAL_SOFT := $(PROJECT_ROOT)/openal-soft-openal-soft-1.19.1
GLFW := $(PROJECT_ROOT)/glfw-boat
DYNCALL := $(PROJECT_ROOT)/dyncall-1.1
DYNCALL_LIB := $(BUILD_DIR)/dyncall/lib
LWJGL3 := $(PROJECT_ROOT)/lwjgl3-boat
TOOLCHAIN_LIBRARY_PATH := $(PROJECT_ROOT)/ndk/aarch64-linux-android-gcc/sysroot/usr/lib



.PHONY : all
all : j2re-image lwjgl-2 lwjgl-3 gl4es glfw openal-soft 

.PHONY : runtime-pack
runtime-pack : runtime-$(VERSION_ARCH)-$(VERSION_NAME).tar.xz
runtime-$(VERSION_ARCH)-$(VERSION_NAME).tar.xz : all
	cd $(BUILD_DIR) ; \
	tar -cJvf runtime-$(VERSION_ARCH)-$(VERSION_NAME).tar.xz j2re-image lwjgl-2 lwjgl-3 libglfw.so libGL.so.1 libopenal.so.1

j2re-image : 
	cp -r $(J2RE_IMAGE) $(BUILD_DIR)
	rm -f $(BUILD_DIR)/j2re-image/lib/*.diz
	rm -f $(BUILD_DIR)/j2re-image/lib/$(JDK_ARCH)/*.diz
	rm -f $(BUILD_DIR)/j2re-image/lib/$(JDK_ARCH)/$(JDK_VM_VARIANT)/*.diz
	rm -f $(BUILD_DIR)/j2re-image/lib/$(JDK_ARCH)/jli/*.diz

boat :
	cd $(BOAT)/jni/boat ; \
	$(TARGET_CC) -o libboat.so $(COMMON_CFLAGS) -std=gnu99 -shared -Wl,--soname=libboat.so,--no-undefined -llog -ldl -landroid -I include/ -DBUILD_BOAT boat.c loadme.c
	mkdir boat
	cp $(BOAT)/jni/boat/libboat.so $(BUILD_DIR)/boat

lwjgl-2 : boat
	cd $(LWJGL2) ; \
	ant $(LWJGL2_ANT_FLAGS) -Djdk.include="$(JDK_INCLUDE)" -Dcross.compile.target="$(VERSION_TARGET)" -Dlwjgl.platform.boat=true -Dboat.include="$(BOAT_INCLUDE)" -Dboat.lib="$(BOAT_LIB)"
	mkdir $(BUILD_DIR)/lwjgl-2
	cp $(LWJGL2)/libs/lwjgl.jar $(BUILD_DIR)/lwjgl-2
	cp $(LWJGL2)/libs/lwjgl_util.jar $(BUILD_DIR)/lwjgl-2
	cp $(LWJGL2)/libs/boat/$(LWJGL2_NATIVE_LIB) $(BUILD_DIR)/lwjgl-2
	

.PHONY : gl4es
gl4es : libGL.so.1
libGL.so.1 : 
	cd $(GL4ES) ; \
	mkdir build ; \
	cd build ; \
	cmake .. -DBCMHOST=1 -DNOX11=1 -DDEFAULT_ES=2 -DUSE_CLOCK=OFF -DCMAKE_C_FLAGS="$(COMMON_CFLAGS) -DANDROID=1" -DCMAKE_C_COMPILER="$(TARGET_CC)" ; \
	make 
	cp $(GL4ES)/lib/libGL.so.1 $(BUILD_DIR)
	
.PHONY : openal-soft
openal-soft : libopenal.so.1
libopenal.so.1 : 
	cd $(OPENAL_SOFT) ; \
	mkdir build ; \
	cd build ; \
	cmake .. -DCMAKE_C_COMPILER="$(TARGET_CC)" -DCMAKE_CXX_COMPILER="$(TARGET_CXX)" -DCMAKE_C_FLAGS="$(OPTIMIZE_CFLAGS)" -DCMAKE_SYSTEM_NAME=Linux -DALSOFT_BACKEND_OSS=OFF -DALSOFT_BACKEND_OPENSL=ON -DALSOFT_BACKEND_WAVE=ON ; \
	make OpenAL
	cp $(OPENAL_SOFT)/build/libopenal.so.1.19.1 $(BUILD_DIR)/libopenal.so.1

.PHONY : glfw
glfw : libglfw.so
libglfw.so : boat
	cd $(GLFW) ; \
	mkdir build ; \
	cd build ; \
	cmake .. -DGLFW_USE_BOAT=ON -DBUILD_SHARED_LIBS=ON -DGLFW_BUILD_EXAMPLES=OFF -DGLFW_BUILD_TESTS=OFF -DGLFW_BUILD_DOCS=OFF -DCMAKE_C_FLAGS="$(OPTIMIZE_CFLAGS)" -DCMAKE_C_COMPILER="$(TARGET_CC)" -DCMAKE_LIBRARY_PATH="$(TOOLCHAIN_LIBRARY_PATH)" -DBOAT_BOAT_INCLUDE_PATH="$(BOAT_INCLUDE)" -DBOAT_BOAT_LIB="$(BOAT_LIB)/libboat.so" -DCMAKE_SKIP_RPATH=ON ; \
	make 
	cp $(GLFW)/build/src/libglfw.so $(BUILD_DIR)

dyncall : 
	mkdir dyncall
	cd $(DYNCALL) ; \
	mkdir build ; \
	export CC=$(TARGET_CC) ; \
	./configure --prefix=$(BUILD_DIR)/dyncall ; \
	make install ; \
	unset CC
	
lwjgl-3 : boat dyncall libglfw.so libopenal.so.1
	cd $(LWJGL3) ; \
	ant -Dbuild.arch="$(LWJGL3_TARGET_ARCH)" -Dplatform.boat=true -Ddyncall.lib="$(DYNCALL_LIB)" -Dglfw.lib="$(BUILD_DIR)" -Dopenal.lib="$(BUILD_DIR)" 
# ant -Dbuild.arch="$(LWJGL3_TARGET_ARCH)" -Dplatform.boat=true -Ddyncall.lib="$(DYNCALL_LIB)" -Dglfw.lib="$(BUILD_DIR)" -Dopenal.lib="$(BUILD_DIR)" release
	mkdir $(BUILD_DIR)/lwjgl-3
	cp $(LWJGL3)/bin/RELEASE/lwjgl/lwjgl.jar $(BUILD_DIR)/lwjgl-3
	cp $(LWJGL3)/bin/RELEASE/lwjgl-glfw/lwjgl-glfw.jar $(BUILD_DIR)/lwjgl-3
	cp $(LWJGL3)/bin/RELEASE/lwjgl-jemalloc/lwjgl-jemalloc.jar $(BUILD_DIR)/lwjgl-3
	cp $(LWJGL3)/bin/RELEASE/lwjgl-openal/lwjgl-openal.jar $(BUILD_DIR)/lwjgl-3
	cp $(LWJGL3)/bin/RELEASE/lwjgl-opengl/lwjgl-opengl.jar $(BUILD_DIR)/lwjgl-3
	cp $(LWJGL3)/bin/RELEASE/lwjgl-stb/lwjgl-stb.jar $(BUILD_DIR)/lwjgl-3
	cp $(LWJGL3)/bin/RELEASE/lwjgl-tinyfd/lwjgl-tinyfd.jar $(BUILD_DIR)/lwjgl-3
	cp $(LWJGL3)/bin/libs/native/boat/$(LWJGL3_TARGET_ARCH)/org/lwjgl/liblwjgl.so $(BUILD_DIR)/lwjgl-3
	cp $(LWJGL3)/bin/libs/native/boat/$(LWJGL3_TARGET_ARCH)/org/lwjgl/opengl/liblwjgl_opengl.so $(BUILD_DIR)/lwjgl-3
	cp $(LWJGL3)/bin/libs/native/boat/$(LWJGL3_TARGET_ARCH)/org/lwjgl/stb/liblwjgl_stb.so $(BUILD_DIR)/lwjgl-3
	cp $(LWJGL3)/bin/libs/native/boat/$(LWJGL3_TARGET_ARCH)/org/lwjgl/tinyfd/liblwjgl_tinyfd.so $(BUILD_DIR)/lwjgl-3
	
.PHONY : help
help :
	@echo ""
	@echo "Boat packages Makefile help"
	@echo "==========================="
	@echo ""
	@echo "Configurations are as following:"
	@echo ".  version name :           $(VERSION_NAME)"
	@echo ".  version arch :           $(VERSION_ARCH)"
	@echo ".  version target :         $(VERSION_TARGET)"
	@echo ".  build directory :        $(BUILD_DIR)"
	@echo ".  common C flags :         $(COMMON_CFLAGS)"
	@echo ""
	@echo "Components are listed below:"
	@echo ".  boat :                   $(BOAT)"
	@echo ".  j2re-image :             $(J2RE_IMAGE)"
	@echo ".  dyncall :                $(DYNCALL)"
	@echo ".  gl4es :                  $(GL4ES)"
	@echo ".  openal-soft :            $(OPENAL_SOFT)"
	@echo ".  glfw :                   $(GLFW)"
	@echo ".  lwjgl-2 :                $(LWJGL2)"
	@echo ".  lwjgl-3 :                $(LWJGL3)"
	@echo ""
	@echo "Make targets:"
	@echo ".  make [default]           # As 'make all'."
	@echo ".  make runtime-pack        # Build up runtime pack."
	@echo ".  make all                 # Build all components."
	@echo ".  make clean               # Remove all built files."
	@echo ".  make <component>         # Build <component> and its dependencies."
	@echo ".  make clean-<component>   # Clean <component> only."
	@echo ""

.PHNOY : clean
clean : clean-gl4es clean-lwjgl-2 clean-openal-soft clean-glfw clean-dyncall clean-boat clean-lwjgl-3 clean-j2re-image clean-runtime-pack

.PHONY : clean-gl4es
clean-gl4es : 
	-rm -rf $(GL4ES)/build
	-rm -rf $(BUILD_DIR)/libGL.so.1

.PHONY : clean-lwjgl-3
clean-lwjgl-3 : 
	-cd $(LWJGL3) ; \
	ant clean
	-rm -rf $(BUILD_DIR)/lwjgl-3

.PHONY : clean-lwjgl-2
clean-lwjgl-2 : 
	-cd $(LWJGL2) ; \
	ant clean
	-rm -rf $(BUILD_DIR)/lwjgl-2

.PHONY : clean-openal-soft
clean-openal-soft : 
	-rm -rf $(OPENAL_SOFT)/build
	-rm -rf $(BUILD_DIR)/libopenal.so.1

.PHONY : clean-glfw
clean-glfw : 
	-rm -rf $(GLFW)/build
	-rm -rf $(BUILD_DIR)/libglfw.so

.PHONY : clean-dyncall
clean-dyncall : 
	-cd $(DYNCALL) ; \
	make clean
	-rm -rf $(DYNCALL)/build
	-rm -rf $(BUILD_DIR)/dyncall
	
.PHONY : clean-boat
clean-boat : 
	-rm -rf $(BUILD_DIR)/boat

.PHONY : clean-j2re-image
clean-j2re-image : 
	-rm -rf $(BUILD_DIR)/j2re-image

.PHONY : clean-runtime-pack
clean-runtime-pack : 
	-rm -rf $(BUILD_DIR)/runtime-$(VERSION_ARCH)-$(VERSION_NAME).tar.xz
