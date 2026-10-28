cmake_minimum_required(VERSION 3.16)
project(tmpl LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

add_compile_options(-Wall -Wextra)

add_executable(tmpl src/main.c)

install(TARGETS tmpl RUNTIME DESTINATION bin)
