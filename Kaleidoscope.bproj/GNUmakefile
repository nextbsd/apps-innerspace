#
#  Kaleidoscope InnerSpace module
#

Kaleidoscope_PRINCIPAL_CLASS = KaleidoscopeView

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = Kaleidoscope
BUNDLE_EXTENSION = .InnerSpace

Kaleidoscope_OBJC_FILES = KaleidoscopeView.m KaleidoscopeGL.m
Kaleidoscope_PRINCIPAL_CLASS = KaleidoscopeView
ifeq ($(shell uname -s),Darwin)
Kaleidoscope_BUNDLE_LIBS += -framework OpenGL
else
Kaleidoscope_BUNDLE_LIBS += -lGL
endif
Kaleidoscope_STANDARD_INSTALL = no

-include GNUmakefile.preamble

-include ../GNUmakefile.local

-include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble
