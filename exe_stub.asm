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

EXTRN	OpenArchive			: PROC
EXTRN	SetProcessDataProc		: PROC
EXTRN	ReadHeader			: PROC
EXTRN	ProcessFile			: PROC
EXTRN	CloseArchive			: PROC
EXTRN	PackFiles			: PROC

	DATASEG

; common data
dir1		DB			"D:\Stas\buf\grp_wincmd\test\", NULL

; data for reading
file1		DB			"C:\Games\DUKE3D\DUKE3D.GRP", NULL
data1		tOpenArchiveData	<offset file1, PK_OM_EXTRACT>
data2		tHeaderData		<?>

; data for writing
new1		DB			"test.grp", NULL
list1		DB			"test1234.dat", NULL
		DB			"test2.dat", NULL
		DB			"test3.dat", NULL
		DB			"test4.dat", NULL
		DB			NULL

	UDATASEG

hArc		HANDLE	?

	CODESEG

Start:
;	call	Read
	call	Write

	call	ExitProcess, 0


Read	PROC
	call	OpenArchive, offset data1
	or	eax, eax
	jz	@@bye
	mov	[hArc], eax

	call	SetProcessDataProc, eax, offset dummy

@@loop:
	call	ReadHeader, [hArc], offset data2
	or	eax, eax
	jnz	@@close
	lea	eax, [data2.FileName]
	call	ProcessFile, [hArc], PK_EXTRACT, offset dir1, eax
	or	eax, eax
	jnz	@@close

	jmp	short @@loop

@@close:
	call	CloseArchive, [hArc]

@@bye:
	ret
Read	ENDP


dummy PROC
	ARG	xFileName:LPSTR, xSize:INTEGER

	xor	eax, eax
	inc	eax
	ret
dummy ENDP


Write	PROC
	call	PackFiles, offset new1, NULL, offset dir1, offset list1, 0	;PK_PACK_MOVE_FILES
	ret
Write	ENDP


END Start
