# This file is for the llvm+clang options that are specific to building
# a cross-toolchain targeting hexagon linux.
set(DEFAULT_SYSROOT "../target/hexagon-unknown-linux-musl/" CACHE STRING "")
set(CLANG_LINKS_TO_CREATE
            hexagon-unknown-linux-musl-clang++
            hexagon-unknown-linux-musl-clang
            hexagon-unknown-none-elf-clang++
            hexagon-unknown-none-elf-clang
            CACHE STRING "")

