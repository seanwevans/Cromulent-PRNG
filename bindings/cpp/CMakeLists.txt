# bindings/cpp/CMakeLists.txt
#
# Standalone build for the header-only C++ engine and its parity test. The test
# compiles the C reference sources directly so it can verify the C++ stream
# against cromulent_next / cromulent_strong_next bit-for-bit.

cmake_minimum_required(VERSION 3.19)
project(cromulent_cpp CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

if (NOT MSVC)
    add_compile_options(-Wall -Wextra)
endif ()

set(REPO_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../..)

add_executable(test_cpp_engine
    test/cpp_engine.cpp
    ${REPO_ROOT}/src/scalar/cromulent_scalar.c
    ${REPO_ROOT}/src/scalar/cromulent_strong.c)

target_include_directories(test_cpp_engine PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${REPO_ROOT}/include)

enable_testing()
add_test(NAME test_cpp_engine COMMAND test_cpp_engine)
