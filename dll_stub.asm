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

	DATASEG

	UDATASEG

	CODESEG

DllEntry PROC hInstDLL:DWORD, reason:DWORD, reserved1:DWORD
	xor	eax, eax
	inc	eax
	ret
DllEntry ENDP

END DllEntry
