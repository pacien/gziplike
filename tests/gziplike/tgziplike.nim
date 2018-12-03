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

import unittest, os, ospaths, osproc, times
import gziplike

suite "main":
  const tempDir = "tmp"

  proc testIdentity(input: string, intermediate = tempDir / "compressed", final = tempDir / "decompressed"): bool =
    let compressionStartTime = getTime()
    compress.transform(input, intermediate)
    echo("compression done in ", getTime() - compressionStartTime)
    echo("compression ratio: ", (intermediate.getFileSize() * 100) div input.getFileSize(), "%")
    let decompressionStartTime = getTime()
    decompress.transform(intermediate, final)
    echo("decompression done in ", getTime() - decompressionStartTime)
    startProcess("cmp", args=[input, final], options={poUsePath}).waitForExit() == 0

  setup: createDir(tempDir)
  teardown: removeDir(tempDir)

  test "identity (text)":
    check testIdentity("license.md")

  test "identity (binary)":
    check testIdentity("tests" / "tests")
