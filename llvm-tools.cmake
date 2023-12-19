
if (NOT DEFINED HOST_CLANG_VER OR ${HOST_CLANG_VER} EQUAL "")
    message(FATAL_ERROR "The host clang/llvm tools version must be defined as 'HOST_CLANG_VER'")
endif()
set(SUFFIX "-${HOST_CLANG_VER}" CACHE STRING "")

set(CMAKE_AR llvm-ar${SUFFIX} CACHE STRING "")
set(CMAKE_NM llvm-nm${SUFFIX} CACHE STRING "")
set(CMAKE_OBJDUMP llvm-objdump${SUFFIX} CACHE STRING "")
set(CMAKE_RANLIB llvm-ranlib${SUFFIX} CACHE STRING "")
set(CMAKE_READELF llvm-readelf${SUFFIX} CACHE STRING "")
set(CMAKE_STRIP llvm-strip${SUFFIX} CACHE STRING "")
