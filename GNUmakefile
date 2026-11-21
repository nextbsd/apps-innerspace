#
# InnerSpace's modules. Each builds a .InnerSpace bundle and installs it
# in the Library's InnerSpace folder ($(GNUSTEP_LIBRARY)/InnerSpace),
# where Workspace's desktop background (apps-workspace, Background/)
# finds it. There is no InnerSpace application any more: choose a module
# in Workspace Preferences > Background.
#

ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(warning )
    $(warning Unable to obtain GNUSTEP_MAKEFILES setting from gnustep-config!)
    $(warning Perhaps gnustep-make is not properly installed,)
    $(warning so gnustep-config is not in your PATH.)
    $(warning )
    $(warning Your PATH is currently $(PATH))
    $(warning )
  endif
endif

ifeq ($(GNUSTEP_MAKEFILES),)
  $(error You need to set GNUSTEP_MAKEFILES before compiling!)
endif

include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME=InnerSpace

#
# Subprojects
#

SUBPROJECTS = Weather.bproj Aquarium.bproj ConnectionMachine.bproj Black.bproj Boxes.bproj SystemStats.bproj \
	Boink.bproj \
	HAL9000.bproj \
	DictionaryWords.bproj \
        BouncyClock.bproj \
        FlyingToasters.bproj \
        Kaleidoscope.bproj \
        TomorrowNeverKnows.bproj \
        SignalHead.bproj \
        StepMan.bproj \
        Neko.bproj \
        NickSpace.bproj Polyhedra.bproj \
	Space2View.bproj SporView.bproj \
	Qix.bproj ItJustStopped.bproj

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble
