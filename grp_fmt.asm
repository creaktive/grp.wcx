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
;    site:	http://sysdlabs.hypermart.net/


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

EXTRN	VirtualAlloc			: PROC
EXTRN	VirtualFree			: PROC

	DATASEG

MAXFILES	EQU	4096
sign		DB	"KenSilverman"

	UDATASEG

grp_entry STRUC
	name		DB	12 DUP (?)
	size		INTEGER	?
grp_entry ENDS


ent		grp_entry	<?>
bytes_rdwr	INTEGER		?

	CODESEG


OpenArchive PROC
	ARG	ArchiveData:PTR
	USES	ecx, ebp, esi, edi

	; restore pointers
	mov	ebp, [ArchiveData]

	; allocate buffer for our handle
	call	VirtualAlloc, 0, SIZE HGRP, MEM_COMMIT, PAGE_READWRITE
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
	mov	ecx, 3
	repz	cmpsd
	pop	edi

	jnz	@@unknown

	; find archive filepath length
	push	edi
	mov	edi, [ebp.HArcName]
	xor	eax, eax
	mov	ecx, 260
	repnz	scasb
	pop	edi
	sub	ecx, 260
	neg	ecx

	; save it
	mov	[edi.arc_len], ecx

	; save archive filepath
	push	edi
	mov	esi, [ebp.HArcName]
	rep	movsb
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

	; copy archive filename
	push	edi
	mov	ecx, [edi.arc_len]
	mov	esi, edi
	mov	edi, ebp
	rep	movsb
	pop	edi

	; copy filename
	push	edi
	mov	esi, offset ent.name
	lea	edi, [ebp.FileName]
	mov	ecx, 3
	rep	movsd
	mov	BYTE PTR [edi], NULL
	pop	edi

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
	call	strcat

@@no_path:
	mov	esi, [DestName]
	or	esi, esi
	jz	@@no_name
	call	strcat

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

	; EDX = last block size
	mov	eax, [edi.psize]
	xor	edx, edx
	mov	ebx, BUFFSIZE
	div	ebx

	; save pointer to our buffer
	lea	ebx, [edi.buff]

	; do we have more than one block?
	or	eax, eax
	jz	@@last

	; ECX = blocks count
	mov	ecx, eax

	; extract packed file
@@copy:
	call	copy, edi, [edi.grp], [hOut], ebx, BUFFSIZE, [FullName]
	.if	eax != 0
@@err_close:
		push	eax
		call	CloseHandle, [hOut]
		call	DeleteFile, [FullName]
		pop	eax
		ret
	.endif
	loop	@@copy

@@last:
	or	edx, edx
	jz	@@close
	call	copy, edi, [edi.grp], [hOut], ebx, edx, [FullName]
	or	eax, eax
	jnz	@@err_close

@@close:
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
	call	VirtualFree, edi, SIZE HGRP, MEM_DECOMMIT

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
	USES	edi

	; restore pointers
	mov	edi, [hArcData]

	; copy value
	mov	eax, [pProcessDataProc]
	mov	[edi.procdata], eax

	ret
SetProcessDataProc ENDP


strcat PROC
	mov	ecx, MAX_PATH

@@copy:
	lodsb
	or	al, al
	jz	@@copy_done
	stosb
	loop	@@copy

@@copy_done:
	ret
strcat ENDP

copy PROC
	ARG	hArcData:HANDLE, from:HANDLE, to:HANDLE, buf:LPVOID, bufsize:INTEGER, fname:LPSTR
	USES	ebx, ecx, edx, edi

	; restore pointers
	mov	edi, [hArcData]

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
	call	[edi.procdata], [fname], [bufsize]
	.if	eax == 0
		mov	eax, E_EABORTED
		ret
	.endif

	; return OK
	xor	eax, eax
	ret
copy ENDP

END
