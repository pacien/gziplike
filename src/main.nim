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

import os, streams, sugar
import bitreader, bitwriter, streamblock

proc transform(operation: (BitReader, BitWriter) -> void, input, output: string) =
  let inputStream = openFileStream(input, fmRead)
  defer: inputStream.close()
  let outputStream = openFileStream(output, fmWrite)
  defer: outputStream.close()
  operation(inputStream.bitReader(), outputStream.bitWriter())

proc compress(bitReader: BitReader, bitWriter: BitWriter) =
  while not bitReader.atEnd():
    let streamBlock = streamblock.readRaw(bitReader)
    streamBlock.writeSerialisedTo(bitWriter)
  bitWriter.flush()

proc decompress(bitReader: BitReader, bitWriter: BitWriter) =
  var hasMore = true
  while hasMore:
    let streamBlock = streamblock.readSerialised(bitReader)
    streamBlock.writeRawTo(bitWriter)
    hasMore = not streamBlock.isLast()
  bitWriter.flush()

proc printUsage(output: File) =
  output.writeLine("Usage: " & paramStr(0) & " <compress|decompress> <input file> <output file>")

when isMainModule:
  if paramCount() != 3:
    stderr.writeLine("Error: invalid argument count.")
    printUsage(stderr)
    quit(1)

  case paramStr(1):
    of "compress": compress.transform(paramStr(2), paramStr(3))
    of "decompress": decompress.transform(paramStr(2), paramStr(3))
    else:
      stderr.writeLine("Error: invalid operation.")
      printUsage(stderr)
      quit(1)
