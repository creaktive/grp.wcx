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


;/* Error codes returned to calling application */
E_END_ARCHIVE		EQU	10	;/* No more files in archive */
E_NO_MEMORY		EQU	11	;/* Not enough memory */
E_BAD_DATA		EQU	12	;/* Data is bad */
E_BAD_ARCHIVE		EQU	13	;/* CRC error in archive data */
E_UNKNOWN_FORMAT	EQU	14	;/* Archive format unknown */
E_EOPEN			EQU	15	;/* Cannot open existing file */
E_ECREATE		EQU	16	;/* Cannot create file */
E_ECLOSE		EQU	17	;/* Error closing file */
E_EREAD			EQU	18	;/* Error reading from file */
E_EWRITE		EQU	19	;/* Error writing to file */
E_SMALL_BUF		EQU	20	;/* Buffer too small */
E_EABORTED		EQU	21	;/* Function aborted by user */
E_NO_FILES		EQU	22	;/* No files found */
E_TOO_MANY_FILES	EQU	23	;/* Too many files to pack */
E_NOT_SUPPORTED		EQU	24	;/* Function not supported */

;/* flags for unpacking */
PK_OM_LIST		EQU	0
PK_OM_EXTRACT		EQU	1

;/* flags for ProcessFile */
PK_SKIP			EQU	0	;/* Skip this file */
PK_TEST			EQU	1	;/* Test file integrity */
PK_EXTRACT		EQU	2	;/* Extract to disk */

;/* Flags passed through ChangeVolProc */
PK_VOL_ASK		EQU	0	;/* Ask user for location of next volume */
PK_VOL_NOTIFY		EQU	1	;/* Notify app that next volume will be unpacked */

;/* Flags for packing */

;/* For PackFiles */
PK_PACK_MOVE_FILES	EQU	1	;/* Delete original after packing        */
PK_PACK_SAVE_PATHS	EQU	2	;/* Save path names of files             */

;/* Returned by GetPackCaps */
PK_CAPS_NEW		EQU	1	;/* Can create new archives              */
PK_CAPS_MODIFY		EQU	2	;/* Can modify exisiting archives        */
PK_CAPS_MULTIPLE	EQU	4	;/* Archive can contain multiple files   */
PK_CAPS_DELETE		EQU	8	;/* Can delete files                     */
PK_CAPS_OPTIONS		EQU	16	;/* Has options dialog                   */


tHeaderData STRUC
	ArcName		DB	260 DUP (?)
	FileName	DB	260 DUP (?)
	Flags		INTEGER	?
	PackSize	INTEGER	?
	UnpSize		INTEGER	?
	HostOS		INTEGER	?
	FileCRC		INTEGER	?
	FileTime	INTEGER	?
	UnpVer		INTEGER	?
	Method		INTEGER	?
	FileAttr	INTEGER	?
	CmtBuf		LPSTR	?
	CmtBufSize	INTEGER	?
	CmtSize		INTEGER	?
	CmtState	INTEGER	?
tHeaderData ENDS

tOpenArchiveData STRUC
	HArcName	LPSTR	?
	OpenMode	INTEGER	?
	OpenResult	INTEGER	?
	HCmtBuf		LPSTR	?
	HCmtBufSize	INTEGER	?
	HCmtSize	INTEGER	?
	HCmtState	INTEGER	?
tOpenArchiveData ENDS


;/* Definition of callback functions called by the DLL
;Ask to swap disk for multi-volume archive */
;typedef int (__stdcall *tChangeVolProc)(char *ArcName,int Mode);

tChangeVolProc		PROCDESC	CALLBACK	:LPSTR, :INTEGER


;/* Notify that data is processed - used for progress dialog */
;typedef int (__stdcall *tProcessDataProc)(char *FileName,int Size);

tProcessDataProc	PROCDESC	CALLBACK	:LPSTR, :INTEGER
