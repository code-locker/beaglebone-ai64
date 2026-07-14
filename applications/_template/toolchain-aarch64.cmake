# CMake toolchain file: cross-compile on an x86_64 host for the BBAI64 (aarch64).
# Usage: cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=toolchain-aarch64.cmake
#
# Requires: sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER   aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

# A72-specific tuning (optional)
set(CMAKE_C_FLAGS_INIT   "-mcpu=cortex-a72")
set(CMAKE_CXX_FLAGS_INIT "-mcpu=cortex-a72")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
