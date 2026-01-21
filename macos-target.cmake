# CMake cache file for cross-compiling to macOS targets using Zig.
# Zig's macOS libc headers don't include full Mach kernel APIs
# (mach/mach.h exception handling) or complete mach-o/dyld.h functions,
# so we disable features that require those APIs.
#
# Note: Platform settings are in macos-toolchain.cmake (loaded via CMAKE_TOOLCHAIN_FILE)

set(LLVM_ENABLE_CRASH_OVERRIDES OFF CACHE BOOL "")
set(LLVM_ENABLE_BACKTRACES OFF CACHE BOOL "")
