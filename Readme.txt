GRP Plugin for Windows Commander v1.0
=====================================


 * How to install this plugin (32 bit only):
--------------------------------------------

1. Unzip the "grp.wcx" to the Wincmd directory (usually C:\wincmd)
2. In Windows Commander 4.0 (or newer), choose Configuration - Options
3. Open the 'Packer' page
4. Click 'Configure packer extension DLLs'
5. type  pak  as the extension
6. Click 'new type', and select the "grp.wcx"
7. Click OK


 * What it does:
----------------

Extract/create support for GRP (Duke Nukem 3D and other Build engine-based
games group file) file format in Windows Commander. List of some games that
uses Build engine, and consequently GRP format to store files:

 o Duke Nukem 3D
 o Blood
 o Shadow Warrior
 o Redneck Rampage
 o Witchhaven
 o TekWar
 o Extreme Paintbrawl
 o Powerslave
 o NAM/Napalm
 o WWII GI
 o ...some sequels, some unreleased games, and a bunch of TCs.

(This list and more info about Build engine can be found at
following URL: http://www.icculus.org/BUILD/)


 * Features:
------------

This plugin was coded in x86 assembly for Win32 environment and
compiled with Turbo Assembler 5.0. So, it's probably the smallest
and the fastest WCX out there. It's also the first WCX I know
programmed in so low-level language. The main purpose of writing
it was fun, of course. But you can also use it as reference
platform to write your own assembly plugins, as the GRP format
itself is probably the simpliest existing. So, plugin has
educational purposes too. Anyway, currently this plugin supports
the widest range of games... Have phun, abandonware-game hackers! =D


* Bugs:
-------

 o Has 5 global (out-of-handle) variables. Really don't know what's going
   to happen if WinCmd called 2 instances of extractor :/
 o Too many macros... ".if eax == 0" commonly used instead of "or eax, eax".
   That's sacrifice I did to keep code cleaner... More than 800 lines of
   code in single file *REALLY* pisses me off!


* TODO:
-------

 o Open TILES###.ART as archive with images. Not necessary in asm, *humpf*
 o IrfanView plugin to decode ANM... Just a dream ;)

* Not-TODO:
-------

 o Modify/delete support. GRP format wasn't designed to support such
   humiliation. It would be faster to extract & rebuild entire archive
   then write such a crap ;)


 * References:
--------------

 o OpenDuke
 o BUILD programmed by Ken Silverman
 o "WCX Writer's Reference" by Christian Ghisler & Jiri Barton
 o ISO Plugin for Windows Commander by Sergey Oblomov
 o PACK Plugin for Windows Commander by DarkOne
 o GRP.WCX 'packed' by "PE Rebuilder v0.96b" By TiTi/PC-BLZ & Virogen/PC
 o "Mastering Turbo Assembler®" book by Tom Swan (simply the best reference
   about TASM!)


 * License:
-----------

    This file is part of GRP_WINCMD, a Windows Commander plugin for GRP (Duke Nukem 3D
    and other games based on Build engine group file) files.
    Copyright (C) 2002  Stanislaw Y. Pusep

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.


 * Author:
----------

Stanislaw Y. Pusep (a.k.a. Stas)

    E-Mail:	stanis@linuxmail.org
    Site:	http://sysdlabs.hypermart.net/
(here you can find this program & other cool things for Duke3D)
