top_srcdir=../../..
include $(top_srcdir)/build/common.mk

ifeq ($(OS),Cygwin)
MACHINE_CONFIG_FILE=--machine-config $(shell cygpath -m $(shell pkg-config --variable=sysconfdir mono))/mono/2.0/machine.config
CC=gcc -mno-cygwin
EXEEXT=.exe
PATHSEP=;
KILLAT=-Wl,--kill-at
ZLIB=libzlib.dll.a
ZLIBDEP=$(ZLIB)
ZIPOPEN=_zipOpen@8
UNZOPEN=_unzOpen@4
OTHERLIBS=-lole32 -loleaut32 -lws2_32 -lpsapi -luser32 -lkernel32
STACKSIZE=-Wl,--stack=20000000
else
ifeq ($(OS),Darwin)
MACHINE_CONFIG_FILE=
else
MACHINE_CONFIG_FILE=--machine-config "`pkg-config --variable=sysconfdir mono`/mono/2.0/machine.config"
endif
ifeq ($(OS),GNU/Linux)
GDIPLUS_LIB=-Wl,--whole-archive -lgdiplus -Wl,--no-whole-archive
GDIPLUS_LIB_ONLY_L=`pkg-config --libs-only-L libgdiplus` -L$(GDIPLUS_LIBDIR)
GDIPLUS_LIB_ONLY_l=`pkg-config --libs-only-l libgdiplus | sed -e "s/\-lgdiplus //"`
GDIPLUS_CONFIG=--config gdiplus.config
else
GDIPLUS_LIB=
GDIPLUS_LIB_ONLY_L=
GDIPLUS_LIB_ONLY_l=
GDIPLUS_CONFIG=
endif
EXEEXT=
PATHSEP=:
EXPORTDYNAMIC=-Wl,--export-dynamic
ZLIB=-lz
ZIPOPEN=zipOpen
UNZOPEN=unzOpen
endif

SOURCE = \
    OdfCommandLineException.cs \
    OdfConverter.cs \
    OoxValidator.cs \
    OdfValidator.cs
DISTFILES=$(SOURCE) \
    zlib.def \
    gdiplus.config \
    Scripte41bc1aee0566b95b29442ba7e2f770f.cs \
    Scriptf4ff3df93ecad2c4cc1cd369a654ff2d.cs

all-local: OdfConverterTest.exe OdfConverter$(EXEEXT)

OdfConverterTest.exe : Makefile $(SOURCE) ../../Common/OdfZipUtils/OdfZipUtils.dll ../../Common/OdfConverterLib/OdfConverterLib.dll ../../Word/Converter/WordConverter.dll ../../Presentation/Converter/Presentation.dll ../../Spreadsheet/Converter/Spreadsheet.dll
	$(CSC) $(CSC_DEBUG) -d:MONO -target:exe -out:$@ \
		-reference:../../Common/OdfZipUtils/OdfZipUtils.dll \
		-reference:../../Common/OdfConverterLib/OdfConverterLib.dll \
		-reference:../../Word/Converter/WordConverter.dll \
		-reference:../../Presentation/Converter/Presentation.dll \
		-reference:../../Spreadsheet/Converter/Spreadsheet.dll \
		$(SOURCE)

OdfConverterTestStatic.exe : $(SOURCE) ../../Common/OdfZipUtils/OdfZipUtilsStatic.dll ../../Common/OdfConverterLib/OdfConverterLibStatic.dll ../../Word/Converter/WordConverterStatic.dll ../../Presentation/Converter/PresentationStatic.dll ../../Spreadsheet/Converter/SpreadsheetStatic.dll
	$(CSC) $(CSC_DEBUG) -d:MONO -target:exe -out:$@ \
		-reference:../../Common/OdfZipUtils/OdfZipUtilsStatic.dll \
		-reference:../../Common/OdfConverterLib/OdfConverterLibStatic.dll \
		-reference:../../Word/Converter/WordConverterStatic.dll \
		-reference:../../Presentation/Converter/PresentationStatic.dll \
		-reference:../../Spreadsheet/Converter/SpreadsheetStatic.dll \
		$(SOURCE)

main.c bundle.o : OdfConverterTestStatic.exe Makefile Scripte41bc1aee0566b95b29442ba7e2f770f.dll Scriptf4ff3df93ecad2c4cc1cd369a654ff2d.dll
	MONO_PATH='../../Common/OdfZipUtils$(PATHSEP)../../Common/OdfConverterLib$(PATHSEP)../../Word/Converter$(PATHSEP)../../Presentation/Converter$(PATHSEP)../../Spreadsheet/Converter' mkbundle2 -c -o main.c -oo bundle.o --deps $(MACHINE_CONFIG_FILE) $(GDIPLUS_CONFIG) OdfConverterTestStatic.exe Scripte41bc1aee0566b95b29442ba7e2f770f.dll Scriptf4ff3df93ecad2c4cc1cd369a654ff2d.dll

Scripte41bc1aee0566b95b29442ba7e2f770f.dll : Scripte41bc1aee0566b95b29442ba7e2f770f.cs
	$(CSC) -t:library $<

Scriptf4ff3df93ecad2c4cc1cd369a654ff2d.dll : Scriptf4ff3df93ecad2c4cc1cd369a654ff2d.cs
	$(CSC) -t:library $<

OdfConverter$(EXEEXT) : main.c bundle.o $(ZLIBDEP) Makefile
	rm -f $@
ifeq ($(OS),Darwin)
# Don't even try static linking to mono as we need to bundle glib and all of
# its dependencies which are not included in a standard Mac OS X installation
	$(CC) -o OdfConverter -Wall `pkg-config --cflags mono` main.c \
		`pkg-config --libs-only-L mono` -bind_at_load -all_load -lz \
	    ../../AdditionalTools/zlib123/contrib/minizip/libzlibwapi.a \
		`pkg-config --libs-only-l mono` bundle.o
else
	$(CC) -o OdfConverter$(EXEEXT) -Wall `pkg-config --cflags mono` main.c \
	    $(STACKSIZE) \
	    $(KILLAT) \
	    bundle.o \
	    $(EXPORTDYNAMIC) \
	    -Wl,--undefined=$(ZIPOPEN) -Wl,--undefined=$(UNZOPEN) \
	    `pkg-config --libs-only-L mono` $(GDIPLUS_LIB_ONLY_L) -L../../AdditionalTools/zlib123/contrib/minizip \
	    -Wl,-Bstatic -lmono -lzlibwapi $(GDIPLUS_LIB) -Wl,-Bdynamic  \
	    `pkg-config --libs-only-l mono | sed -e "s/\-lmono //"` \
	    $(GDIPLUS_LIB_ONLY_l) \
	    $(ZLIB) $(OTHERLIBS)
endif
ifeq ($(OS),Cygwin)
	    strip --strip-unneeded $@
endif

# Construct the import library manually from the def file so that we
# don't have to bother with creating a patch to bundle it (a binary
# file), and can bundle just the def file.
libzlib.dll.a: zlib.def
	dlltool -D zlib1.dll -d zlib.def -l libzlib.dll.a


check-local: all
	rm -f /tmp/foo.odt
	MONO_TRACE_LISTENER=Console.Error ./OdfConverter /LEVEL 1 /I /tmp/tst.docx /O /tmp/foo.odt 
	MONO_TRACE_LISTENER=Console.Error ./OdfConverter /LEVEL 1 /I /tmp/foo.odt /O /tmp/baa.docx 

clean-local:
	rm -f *.exe OdfConverterTest$(EXEEXT) *.mdb *.pdb main.c bundle.o libzlib.dll.a

install-local: OdfConverter
	install -D OdfConverter $(DESTDIR)/usr/lib/ooo-2.0/program/OdfConverter

dist-local: dist-common
