
set(LLVM_TARGETS_TO_BUILD "Hexagon" CACHE STRING "")
set(LLVM_DEFAULT_TARGET_TRIPLE "hexagon-unknown-linux-musl" CACHE STRING "")
set(CLANG_DEFAULT_CXX_STDLIB "libc++" CACHE STRING "")
set(CLANG_DEFAULT_OBJCOPY "llvm-objcopy" CACHE STRING "")
set(CLANG_DEFAULT_RTLIB "compiler-rt" CACHE STRING "")
set(CLANG_DEFAULT_UNWINDLIB "libunwind" CACHE STRING "")
set(CLANG_DEFAULT_LINKER "lld" CACHE STRING "")
set(DEFAULT_SYSROOT "../target/hexagon-unknown-linux-musl/" CACHE STRING "")
set(LLVM_ENABLE_PROJECTS "clang;lld" CACHE STRING "")

set(CLANG_LINKS_TO_CREATE hexagon-unknown-linux-musl-clang++ hexagon-unknown-linux-musl-clang CACHE STRING "")

