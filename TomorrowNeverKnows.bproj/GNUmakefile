#
#  Tomorrow Never Knows InnerSpace module
#

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = TomorrowNeverKnows
BUNDLE_EXTENSION = .InnerSpace

TomorrowNeverKnows_OBJC_FILES = TomorrowNeverKnowsView.m
TomorrowNeverKnows_PRINCIPAL_CLASS = TomorrowNeverKnowsView
ifeq ($(shell uname -s),Darwin)
TomorrowNeverKnows_BUNDLE_LIBS += -framework OpenGL
else
TomorrowNeverKnows_BUNDLE_LIBS += -lGL
endif
TomorrowNeverKnows_STANDARD_INSTALL = no

-include GNUmakefile.preamble

-include ../GNUmakefile.local

-include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble
