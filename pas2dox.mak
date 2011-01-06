# pas2dox VC++ 6.0 makefile

PROJECT=pas2dox.exe
OUTDIR=Release

OBJECTS= \
	"$(OUTDIR)\pas2dox.obj"

CPP=cl.exe
CFLAGS=/nologo /GX /ML /O1 /W3 /Fo"$(OUTDIR)\\" /I.\\

LINK=link.exe
LFLAGS=/nologo /out:"$(OUTDIR)\$(PROJECT)"

LEX=flex
LEXFLAGS=-i

##############################################################################

all : "$(OUTDIR)\$(PROJECT)"
	bash testsuite.sh ./$(OUTDIR)/$(PROJECT)

clean :
	-@del /F /Q "$(OUTDIR)"

notest : "$(OUTDIR)\$(PROJECT)"


"$(OUTDIR)" :
	if not exist "$(OUTDIR)\" mkdir "$(OUTDIR)"

"$(OUTDIR)\$(PROJECT)" : "$(OUTDIR)" $(OBJECTS)
	$(LINK) $(LFLAGS) $(OBJECTS)

.cpp{$(OUTDIR)}.obj :
	$(CPP) $(CFLAGS) /c $<

pas2dox.cpp : pas2dox.l
	$(LEX) $(LEXFLAGS) -opas2dox.cpp pas2dox.l