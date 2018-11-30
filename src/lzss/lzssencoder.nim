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

import lists
import listpolyfill, matchtable, lzssnode, lzsschain

const matchGroupLength = 3
const maxRefByteLength = high(uint8).int + matchGroupLength
let emptySinglyLinkedList = initSinglyLinkedList[int]()

proc commonPrefixLength*(a, b: openArray[uint8], skipFirst, maxLength: int): int =
  result = skipFirst
  let maxPrefixLength = min(min(a.len, b.len), maxLength)
  while result < maxPrefixLength and a[result] == b[result]: result += 1

proc longestPrefix*(candidatePos: SinglyLinkedList[int], searchBuf, lookAheadBuf: openArray[uint8]): tuple[length, pos: int] =
  for startIndex in candidatePos.items:
    let prefixLength = commonPrefixLength(
      searchBuf.toOpenArray(startIndex, searchBuf.len - 1), lookAheadBuf, matchGroupLength, maxRefByteLength)
    if prefixLength > result.length: result = (prefixLength, startIndex)
    if prefixLength >= maxRefByteLength: return

proc addGroups*(matchTable: MatchTable[seq[uint8], int], buffer: openArray[uint8], fromPosIncl, toPosExcl: int) =
  for cursor in fromPosIncl..(toPosExcl - matchGroupLength):
    let group = buffer[cursor..<(cursor + matchGroupLength)]
    matchTable.addMatch(group, cursor)

proc lzssEncode*(buf: openArray[uint8]): LzssChain =
  result = initSinglyLinkedList[LzssNode]()
  let matchTable = initMatchTable(seq[uint8], int)
  var cursor = 0
  while cursor < buf.len() - matchGroupLength:
    let matches = matchTable.matchList(buf[cursor..<(cursor + matchGroupLength)])
    let prefix = matches.longestPrefix(buf.toOpenArray(0, cursor - 1), buf.toOpenArray(cursor, buf.len - 1))
    if prefix.length > 0:
      result.append(lzssReference(prefix.length, cursor - prefix.pos))
      cursor += prefix.length
    else:
      result.append(lzssCharacter(buf[cursor]))
      cursor += 1
    if cursor - prefix.length >= matchGroupLength:
      matchTable.addGroups(buf, cursor - prefix.length - matchGroupLength, cursor)
  while cursor < buf.len:
    result.append(lzssCharacter(buf[cursor]))
    cursor += 1
