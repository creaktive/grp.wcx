;    This file is part of GRP_WINCMD, a Windows Commander plugin for GRP (Duke Nukem 3D
;    and other games based on Build engine group file) files.
;    Copyright (C) 2002  Stanislaw Y. Pusep
;
;    This program is free software; you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation; either version 2 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program; if not, write to the Free Software
;    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
;
;    E-Mail:	stanis@linuxmail.org
;    Site:	http://sysdlabs.hypermart.net/


	P486
	MODEL   flat, stdcall
	JUMPS
	LOCALS

INCLUDE W32.inc
INCLUDE wcx.inc
INCLUDE	hgrp.inc

GLOBAL	OpenArchive			: PROC
GLOBAL	ReadHeader			: PROC
GLOBAL	ProcessFile			: PROC
GLOBAL	CloseArchive			: PROC
GLOBAL	SetChangeVolProc		: PROC
GLOBAL	SetProcessDataProc		: PROC
GLOBAL	GetPackerCaps			: PROC
GLOBAL	ConfigurePacker			: PROC
GLOBAL	PackFiles			: PROC

EXTRN	VirtualAlloc			: PROC
EXTRN	VirtualFree			: PROC

	DATASEG

grp_entry STRUC
	name		DB	12 DUP (?)
	size		INTEGER	?
grp_entry ENDS


MAXFILES	EQU	4096
CRLF		EQU	0Dh, 0Ah

grp_capt	DB	"GRP Plugin v1.01", NULL
grp_text	DB	"Duke3D and other Build engine-based group file un/packer", CRLF
		DB	CRLF
		DB	"Copyright © 2002  Stanislaw Y. Pusep", CRLF
		DB	"stanis@linuxmail.org", CRLF
		DB	"http://sysdlabs.hypermart.net/proj/", NULL
bigname		DB	"Can't pack filenames not in MS-DOS 8.3 format!", NULL
dirname		DB	"Can't pack sub-directories!", NULL
delete		DB	"Erasing "

sign		grp_entry	<"KenSilverman", 0>

ProcessData	DD	offset	dummy

	UDATASEG

ent		grp_entry	<?>
bytes_rdwr	INTEGER		?

deletemsg	DD	2 DUP (?)
namebuf		DB	MAX_PATH DUP (?)

	CODESEG

; ***************************************************************************
;	Dumb Macros
; ***************************************************************************


malloc MACRO memsize
	call	VirtualAlloc, 0, memsize, MEM_COMMIT, PAGE_READWRITE
ENDM

free MACRO memblock, memsize
	call	VirtualFree, memblock, memsize, MEM_DECOMMIT
ENDM


; ***************************************************************************
;	Plugin Exports
; ***************************************************************************


OpenArchive PROC
	ARG	ArchiveData:PTR
	USES	ecx, ebp, esi, edi

	; restore pointers
	mov	ebp, [ArchiveData]

	; allocate buffer for our handle
	malloc	<SIZE HGRP>
	.if	eax == 0
		mov	[ebp.OpenResult], E_NO_MEMORY
		xor	eax, eax
		ret
	.endif

	; save main handle
	mov	edi, eax

	; open archive
	call	CreateFile, [ebp.HArcName], GENERIC_READ, FILE_SHARE_READ,\
		0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
	.if	eax == INVALID_HANDLE_VALUE
		mov	[ebp.OpenResult], E_EOPEN
		xor	eax, eax
		ret
	.endif

	; save file handle
	mov	[edi.grp], eax

	; check file size
	call	GetFileSize, eax, NULL
	cmp	eax, (SIZE grp_entry) * 2
	jb	@@unknown

	; save file size for future checks
	mov	[edi.grp_size], eax

	; check header
	call	ReadFile, [edi.grp], offset ent, SIZE grp_entry, offset bytes_rdwr, 0
	.if	[bytes_rdwr] != SIZE grp_entry
@@unknown:
		; what's that?
		call	CloseHandle, [edi.grp]
		mov	[ebp.OpenResult], E_UNKNOWN_FORMAT
		xor	eax, eax
		ret
	.endif

	mov	eax, [ent.size]
	cmp	eax, MAXFILES
	ja	@@unknown

	; save number of files
	mov	[edi.nfiles], eax
	inc	eax
	shl	eax, 4
	; save first file offset
	mov	[edi.poffs], eax
	; save first dir entry offset
	mov	[edi.doffs], SIZE grp_entry

	; check file signature
	push	edi
	mov	esi, offset ent.name
	mov	edi, offset sign
	mov	ecx, 12 / 4
	repz	cmpsd
	pop	edi

	jnz	@@unknown

	; save archive filepath/length
	push	edi
	mov	esi, [ebp.HArcName]
	call	strcat, 260
	mov	[edi.arc_len], eax
	pop	edi

	; return pointer to handle
	mov	eax, edi
	ret
OpenArchive ENDP

ReadHeader PROC
	ARG	hArcData:HANDLE, HeaderData:PTR
	USES	ecx, ebp, esi, edi

	; restore pointers
	mov	edi, [hArcData]
	mov	ebp, [HeaderData]

	; move to desired entry
	call	SetFilePointer, [edi.grp], [edi.doffs], NULL, FILE_BEGIN
	.if	eax == 0
		mov	eax, E_BAD_DATA
		ret
	.endif

	; read file entry
	call	ReadFile, [edi.grp], offset ent, SIZE grp_entry, offset bytes_rdwr, 0
	.if	[bytes_rdwr] != SIZE grp_entry
		mov	eax, E_UNKNOWN_FORMAT
		ret
	.endif

	;;;;;;;;;;;
	push	edi

	; copy archive filename
	mov	ecx, [edi.arc_len]
	mov	esi, edi
	mov	edi, ebp
	rep	movsb

	; copy filename
	mov	esi, offset ent.name
	lea	edi, [ebp.FileName]
	mov	ecx, 12 / 4
	rep	movsd
	mov	BYTE PTR [edi], NULL

	pop	edi
	;;;;;;;;;;;

	; set up the rest
	mov	[ebp.Flags],		0

	mov	eax, [ent.size]
	mov	[ebp.PackSize],		eax
	mov	[ebp.UnpSize],		eax
	mov	[edi.psize],		eax

	mov	[ebp.HostOS],		0
	mov	[ebp.FileCRC],		0
	mov	[ebp.FileTime],		0
	mov	[ebp.UnpVer],		0
	mov	[ebp.Method],		0
	mov	[ebp.FileAttr],		0

	mov	[ebp.CmtBuf],		NULL
	mov	[ebp.CmtBufSize],	0
	mov	[ebp.CmtSize],		0
	mov	[ebp.CmtState],		0

	; check if reached the end
	.if	[edi.nfiles] == 0
		mov	eax, E_END_ARCHIVE
		ret
	.endif

	; count down files
	dec	[edi.nfiles]
	; move up dir pointer
	add	[edi.doffs], SIZE grp_entry

	; return OK
	xor	eax, eax
	ret
ReadHeader ENDP

ProcessFile PROC
	ARG	hArcData:HANDLE, Operation:INTEGER, DestPath:LPSTR, DestName:LPSTR
	USES	ebx, ecx, edx, esi, edi
	LOCAL	hOut:HANDLE, FullName:LPSTR

	; restore pointers
	mov	edi, [hArcData]
	lea	eax, [edi.savepath]
	mov	[FullName], eax

	; move to packed file
	call	SetFilePointer, [edi.grp], [edi.poffs], NULL, FILE_BEGIN
	.if	eax == 0
		mov	eax, E_BAD_DATA
		ret
	.endif

	; check file pointer
	mov	edx, [edi.poffs]
	add	edx, [edi.psize]
	.if	edx > [edi.grp_size]
		mov	eax, E_BAD_DATA
		ret
	.endif

	; update file pointer
	mov	[edi.poffs], edx

	; return 0 if PK_SKIP or PK_TEST
	.if	[Operation] != PK_EXTRACT
		xor	eax, eax
		ret
	.endif

	; build full save path
	push	edi
	mov	edi, [FullName]
	mov	esi, [DestPath]
	or	esi, esi
	jz	@@no_path
	call	strcat, MAX_PATH

@@no_path:
	mov	esi, [DestName]
	or	esi, esi
	jz	@@no_name
	call	strcat, MAX_PATH

@@no_name:
	mov	BYTE PTR [edi], NULL
	pop	edi

	; open destination file
	call	CreateFile, [FullName], GENERIC_WRITE, FILE_SHARE_READ,\
		0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
	.if	eax == INVALID_HANDLE_VALUE
		mov	eax, E_ECREATE
		ret
	.endif

	; save file handle
	mov	[hOut], eax

	; save pointer to our buffer
	lea	ebx, [edi.buff]

	; extract packed file
	call	copy, [edi.grp], eax, ebx, BUFFSIZE, [edi.psize], [FullName]
	.if	eax != 0
		push	eax
		call	CloseHandle, [hOut]
		call	DeleteFile, [FullName]
		pop	eax
		ret
	.endif

	; close unpacked file
	call	CloseHandle, [hOut]
	.if	eax == 0
		mov	eax, E_ECLOSE
		ret
	.endif

	; return OK
	xor	eax, eax
	ret
ProcessFile ENDP

CloseArchive PROC
	ARG	hArcData:HANDLE
	USES	edi

	; restore pointers
	mov	edi, [hArcData]

	; close file
	call	CloseHandle, [edi.grp]
	.if	eax == 0
		mov	eax, E_ECLOSE
		ret
	.endif

	; release memory
	free	edi, <SIZE HGRP>

	; return OK
	xor	eax, eax
	ret
CloseArchive ENDP

SetChangeVolProc PROC
	ARG	hArcData:HANDLE, pChangeVolProc1:PTR

	ret
SetChangeVolProc ENDP

SetProcessDataProc PROC
	ARG	hArcData:HANDLE, pProcessDataProc:PTR

	; copy value
	mov	eax, [pProcessDataProc]
	mov	[ProcessData], eax

	ret
SetProcessDataProc ENDP


GetPackerCaps PROC
	mov	eax, PK_CAPS_NEW + PK_CAPS_OPTIONS
	ret
GetPackerCaps ENDP


ConfigurePacker PROC
	ARG	Parent:HWND, DllInstance:HINSTANCE

	call	MessageBox, [Parent], offset grp_text, offset grp_capt, MB_OK + MB_ICONINFORMATION

	ret
ConfigurePacker ENDP


PackFiles PROC
	ARG	PackedFile:LPSTR, SubPath:LPSTR, SrcPath:LPSTR, AddList:LPSTR, PackFlags:INTEGER
	USES	ebx, ecx, edx, edi, esi
	LOCAL	packfile:LPSTR, dirsize:INTEGER, newdir:LPVOID, newgrp:HANDLE

	; check first
	.if	[SubPath] != NULL
@@subdir:
		call	MessageBox, NULL, offset dirname, offset grp_capt, MB_OK + MB_ICONERROR + MB_TASKMODAL
		mov	eax, E_NOT_SUPPORTED
		ret
	.endif
	; just ignore as that's damn default :P
;	test	[PackFlags], PK_PACK_SAVE_PATHS
;	jnz	@@subdir

	; store path to save
	mov	esi, [SrcPath]
	mov	edi, offset namebuf
	call	strcat, MAX_PATH
	mov	[packfile], edi

	; scan AddList
	call	scanlist, [AddList]
	.if	eax == 0
		mov	eax, E_NOT_SUPPORTED
		ret
	.elseif	eax > MAXFILES
		mov	eax, E_TOO_MANY_FILES
		ret
	.endif

	; save directory size
	mov	[sign.size], eax
	inc	eax
	shl	eax, 4
	mov	[dirsize], eax

	; allocate buffer for directory
	malloc	[dirsize]
	.if	eax == 0
		mov	eax, E_NO_MEMORY
		ret
	.endif

	; save pointer to buffer
	mov	[newdir], eax
	mov	edi, eax

	; open destination file
	call	CreateFile, [PackedFile], GENERIC_WRITE, FILE_SHARE_READ,\
		0, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL
	.if	eax == INVALID_HANDLE_VALUE
		mov	eax, E_ECREATE
		ret
	.endif

	; save file handle
	mov	[newgrp], eax

	; skip directory
	call	SetFilePointer, eax, [dirsize], NULL, FILE_BEGIN
	.if	eax == 0
		mov	eax, E_ECREATE
		ret
	.endif

	; prepare buffer
	mov	esi, offset sign
	mov	ecx, (SIZE grp_entry) / 4
	rep	movsd


	; build directory
	mov	esi, [AddList]
	mov	ecx, [sign.size]

@@build:
	call	nextent, [newgrp], [packfile]
	.if	eax != 0
		push	eax
		free	[newdir], [dirsize]
		call	DeleteFile, [PackedFile]
		pop	eax
		ret
	.endif
	loop	@@build


	; restore pointer to buffer
	mov	edi, [newdir]

	; rewind
	call	SetFilePointer, [newgrp], 0, NULL, FILE_BEGIN
	.if	eax == -1
		mov	eax, E_EWRITE
		ret
	.endif

	; write directory
	call	WriteFile, [newgrp], [newdir], [dirsize], offset bytes_rdwr, 0
	mov	edx, [dirsize]
	.if	[bytes_rdwr] != edx
		mov	eax, E_EWRITE
		ret
	.endif

	; close file
	call	CloseHandle, [newgrp]
	.if	eax == 0
		mov	eax, E_ECLOSE
		ret
	.endif

	; release memory
	free	[newdir], [dirsize]
	.if	eax == 0
		mov	eax, E_SMALL_BUF
		ret
	.endif

	; delete files if user wishes so
	test	[PackFlags], PK_PACK_MOVE_FILES
	jz	@@normal
	call	deletelist, [AddList], [sign.size], [packfile]

	; return OK
@@normal:
	xor	eax, eax
	ret
PackFiles ENDP


; ***************************************************************************
;	Plugin Internals
; ***************************************************************************


; ===========================================================================
; strcat (len) - concatenates strings up to NULL or len
;
; * Input:
;	len	= max length to copy
;	ESI	= source string
;	EDI	= destiny string
;
; * Output:
;	EAX	= number of chars copied
;	ECX	= len - EAX
;
; ===========================================================================

strcat PROC
	ARG	len:INTEGER

	mov	ecx, [len]

@@copy:
	lodsb
	or	al, al
	jz	@@copy_done
	stosb
	loop	@@copy

@@copy_done:
	mov	eax, ecx
	sub	eax, [len]
	neg	eax

	ret
strcat ENDP


; ===========================================================================
; scanlist (list) - preparses "AddList" data
;
; * Input:
;	list	= pointer to AddList
;
; * Output:
;	EAX	= number of files in list (0 if error)
;
; ===========================================================================

scanlist PROC
	ARG	list:LPSTR
	USES	ebx, ecx, edx, esi

	mov	esi, [list]
	xor	ebx, ebx

@@newstr:
	mov	ecx, MAX_PATH
	xor	edx, edx

@@scan:
	lodsb

	.if	al == 0
		.if	edx == 0
			jmp	short @@endscan
		.elseif	edx > 12
@@msdos:
			call	MessageBox, NULL, offset bigname, offset grp_capt, MB_OK + MB_ICONERROR + MB_TASKMODAL
			xor	eax, eax
			ret
		.else
			inc	ebx
			jmp	short @@newstr
		.endif
	.elseif	al == ' '
		jmp	short @@msdos
	.elseif	al == '\'
		call	MessageBox, NULL, offset dirname, offset grp_capt, MB_OK + MB_ICONERROR + MB_TASKMODAL
		xor	eax, eax
		ret
	.endif

	inc	edx
	loop	@@scan

@@endscan:
	mov	eax, ebx
	ret
scanlist ENDP


; ===========================================================================
; nextent (to, packfile) - stores next file
;
; * Input:
;	to	= output file handle
;	packfile= pointer to end of path buffer
;
; * Output:
;	EAX	= 0 on success; else WinCmd error code
;
; ===========================================================================

nextent PROC
	ARG	to:HANDLE, packfile:LPSTR
	USES	ecx, edx
	LOCAL	from:HANDLE, copysize:INTEGER, buf:LPVOID

	; store filename in directory/name buffer
	mov	ecx, 13
	mov	edx, [packfile]

@@copy:
	; load character
	lodsb

	; weird but works ;)
	xchg	edi, edx
	stosb
	xchg	edi, edx

	; convert to uppercase
	.if	al >= 'a'
		.if	al <= 'z'
			sub	al, ('a' - 'A')
		.endif
	.endif

	; reached the end?
	or	al, al
	jz	@@copy_done

	; store character
	stosb

	; go until reach NULL or ECX == 0
	loop	@@copy

@@copy_done:
	dec	ecx
	add	edi, ecx

	; open file to be packed
	call	CreateFile, offset namebuf, GENERIC_READ, FILE_SHARE_READ,\
		0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
	.if	eax == INVALID_HANDLE_VALUE
		mov	eax, E_EOPEN
		ret
	.endif

	; save handle
	mov	[from], eax

	; check file size
	call	GetFileSize, eax, NULL
	.if	eax == -1
		mov	eax, E_EOPEN
		ret
	.endif

	; save size in directory
	mov	[copysize], eax
	stosd

	; allocate buffer for transfer
	malloc	BUFFSIZE
	.if	eax == 0
		mov	eax, E_SMALL_BUF
		ret
	.endif

	; save pointer
	mov	[buf], eax

	; pack file
	call	copy, [from], [to], [buf], BUFFSIZE, [copysize], offset namebuf
	.if	eax != 0
		push	eax
		call	CloseHandle, [to]
		free	[buf], BUFFSIZE
		pop	eax
		ret
	.endif

	; release memory
	free	[buf], BUFFSIZE
	.if	eax == 0
		mov	eax, E_SMALL_BUF
		ret
	.endif

	; close file
	call	CloseHandle, [from]
	.if	eax == 0
		mov	eax, E_ECLOSE
		ret
	.endif

	; return OK
	xor	eax, eax
	ret
nextent ENDP


; ===========================================================================
; copy (from, to, buf, bufsize, totsize, fname) - copies multiple blocks
;
; * Input:
;	from	= "from" file handle
;	to	= "to" file handle
;	buf	= pointer to transfer buffer
;	bufsize	= size of transfer buffer
;	totsize	= size of all data
;	fname	= current filename
;
; * Output:
;	EAX	= 0 on success; else WinCmd error code
;
; ===========================================================================

copy PROC
	ARG	from:HANDLE, to:HANDLE, buf:LPVOID, bufsize:INTEGER, totsize:INTEGER, fname:LPSTR
	USES	ebx, ecx, edx

	; EDX = last block size
	mov	eax, [totsize]
	xor	edx, edx
	mov	ebx, [bufsize]
	div	ebx

	; do we have more than one block?
	or	eax, eax
	jz	@@last

	; ECX = blocks count
	mov	ecx, eax

	; extract packed file
@@copy:
	call	copyblock, [from], [to], [buf], BUFFSIZE, [fname]
	.if	eax != 0
		ret
	.endif
	loop	@@copy

@@last:
	or	edx, edx
	jz	@@close
	call	copyblock, [from], [to], [buf], edx, [fname]

@@close:
	ret
copy ENDP


; ===========================================================================
; copyblock (from, to, buf, bufsize, fname) - transfers a block of data between two file handles
;
; * Input:
;	from	= "from" file handle
;	to	= "to" file handle
;	buf	= pointer to transfer buffer
;	bufsize	= size of transfer buffer
;	fname	= current filename
;
; * Output:
;	EAX	= 0 on success; else WinCmd error code
;
; ===========================================================================

copyblock PROC
	ARG	from:HANDLE, to:HANDLE, buf:LPVOID, bufsize:INTEGER, fname:LPSTR
	USES	ebx, ecx, edx

	; read block
	call	ReadFile, [from], [buf], [bufsize], offset bytes_rdwr, 0
	mov	edx, [bufsize]
	.if	[bytes_rdwr] != edx
		mov	eax, E_EREAD
		ret
	.endif

	; write block
	call	WriteFile, [to], [buf], [bufsize], offset bytes_rdwr, 0
	mov	edx, [bufsize]
	.if	[bytes_rdwr] != edx
		mov	eax, E_EWRITE
		ret
	.endif

	; update process indicator
	call	[ProcessData], [fname], [bufsize]
	.if	eax == 0
		mov	eax, E_EABORTED
		ret
	.endif

	; return OK
	xor	eax, eax
	ret
copyblock ENDP


; ===========================================================================
; deletelist (list, entn, packfile) - deletes files specified in "AddList"
;
; * Input:
;	list	= pointer to AddList
;	entn	= number of filenames in AddList
;	packfile= pointer to end of path buffer
;
; * Output:
;	none
;
; ===========================================================================

deletelist PROC
	ARG	list:LPSTR, entn:INTEGER, packfile:LPSTR
	USES	ecx, esi, edi

	; creepy
	mov	esi, offset delete
	mov	edi, offset deletemsg
	movsd
	movsd

	; process AddList
	mov	ecx, [entn]
	mov	esi, [list]

@@delete:
	mov	edi, [packfile]

	push	ecx
	call	strcat, 13
	mov	BYTE PTR [edi], NULL
	call	[ProcessData], offset deletemsg, 0
	call	DeleteFile, offset namebuf
	pop	ecx

	loop	@@delete

	ret
deletelist ENDP


; ===========================================================================
; dummy (xFileName, xSize) - dummy "tProcessDataProc" callback
;
; * Input:
;	xFileName	= name of file being processed
;	xSize		= size of those file
;
; * Output:
;	EAX	= 0 if user cancelled action
;
; ===========================================================================

dummy PROC
	ARG	xFileName:LPSTR, xSize:INTEGER

	xor	eax, eax
	inc	eax
	ret
dummy ENDP


END
