# gzip-like LZSS compressor
# Copyright (C) 2018  Pacien TRAN-GIRARD
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

type LzssNodeKind* = enum
  character,
  reference

type LzssNode* = object
  case kind*: LzssNodeKind
    of character:
      character*: uint8
    of reference:
      length*: int
      relativePos*: int

proc lzssCharacter*(value: uint8): LzssNode =
  LzssNode(kind: character, character: value)

proc lzssReference*(length, relativePos: int): LzssNode =
  LzssNode(kind: reference, length: length, relativePos: relativePos)

proc `==`*(a, b: LzssNode): bool =
  if a.kind != b.kind: return false
  case a.kind:
    of character: a.character == b.character
    of reference: a.length == b.length and a.relativePos == b.relativePos
