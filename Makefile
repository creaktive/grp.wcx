NAME = grp
DEF  = $(NAME).def
RES  = $(NAME).res

!if $d(DEBUG)
TASMDEBUG=/zi
LINKDEBUG=/v
!else
TASMDEBUG=
LINKDEBUG=
!endif

!if $d(MAKEDIR)
IMPORT=$(MAKEDIR)\..\lib\import32
!else
IMPORT=import32
!endif


$(NAME).wcx: dll_stub.obj grp_fmt.obj $(DEF)
  tlink32 /V4.0 /x /Tpd /aa /c $(LINKDEBUG) dll_stub.obj grp_fmt.obj,$(NAME).wcx,,$(IMPORT),$(DEF)

$(NAME).exe: exe_stub.obj grp_fmt.obj
  brc32 -r $(NAME)
  tlink32 /V4.0 /x /Tpe /aa /c $(LINKDEBUG) exe_stub.obj grp_fmt.obj,$(NAME).exe,,$(IMPORT)

.asm.obj:
  tasm32 $(TASMDEBUG) /ml /m2 $&.asm
