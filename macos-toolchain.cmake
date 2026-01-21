# CMake toolchain file for cross-compiling to macOS targets using Zig.
# NOTE: We intentionally do NOT set CMAKE_SYSTEM_NAME=Darwin because that
# triggers Apple-specific linker flags (-all_load) that Zig's lld doesn't
# support. Instead, we set individual Darwin-related variables.

# Mark as cross-compiling but don't trigger full Darwin platform behavior
set(CMAKE_CROSSCOMPILING TRUE)
set(CMAKE_SYSTEM_PROCESSOR arm64)

# Set macOS deployment target (affects compiler flags like -mmacosx-version-min)
set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0" CACHE STRING "")

# macOS shared library suffixes
set(CMAKE_SHARED_LIBRARY_SUFFIX ".dylib")
set(CMAKE_SHARED_MODULE_SUFFIX ".so")  # Use .so for modules to match non-Darwin behavior

# Install name settings for dylibs
set(CMAKE_INSTALL_NAME_DIR "@rpath")
set(CMAKE_BUILD_WITH_INSTALL_NAME_DIR ON)
set(CMAKE_MACOSX_RPATH ON)

# rpath support (Darwin.cmake normally sets this based on OS version check)
set(CMAKE_SHARED_LIBRARY_RUNTIME_C_FLAG "-Wl,-rpath,")
set(CMAKE_SHARED_LIBRARY_RUNTIME_CXX_FLAG "-Wl,-rpath,")
