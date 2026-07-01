# Package
version       = "0.1.0"
author        = "Cromulent PRNG contributors"
description   = "The Cromulent PRNG (Nim port of the scalar reference generator)"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 1.6.0"

task test, "Run the self-test":
  exec "nim c -r --hints:off tests/test_cromulent.nim"
