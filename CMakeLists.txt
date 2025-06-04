# cromulent‑prng CMakeLists.txt

cmake_minimum_required(VERSION 3.19)
project(cromulent_prng C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

if (MSVC)
    add_compile_options(/W4 /WX)
else ()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif ()

set(CROMULENT_SRCS
    src/cromulent_registry.c

    src/scalar/cromulent_scalar.c
    src/scalar/cromulent_strong.c

    src/reference/pcg64.c
    src/reference/splitmix64.c
    src/reference/xoshiro256.c
)

include(CheckCCompilerFlag)
check_c_compiler_flag(-mavx2 HAS_AVX2)

if (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|amd64" AND HAS_AVX2)
    list(APPEND CROMULENT_SRCS src/simd/cromulent_avx2.c)
endif ()

add_library(cromulent STATIC ${CROMULENT_SRCS})
target_include_directories(cromulent PUBLIC ${PROJECT_SOURCE_DIR}/include)

if (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|amd64" AND HAS_AVX2)
    target_compile_options(cromulent PRIVATE -mavx2)
endif ()

add_executable(bench_micro apps/bench_micro.c)
target_link_libraries(bench_micro cromulent)

add_executable(dump_raw apps/dump_raw.c)
target_link_libraries(dump_raw cromulent)

add_executable(sanity apps/sanity.c)
target_link_libraries(sanity cromulent)

enable_testing()
add_test(NAME sanity COMMAND sanity)

install(TARGETS cromulent
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        RUNTIME DESTINATION bin)

install(DIRECTORY include/ DESTINATION include)

add_subdirectory(tests/unit)

add_custom_target(check
    COMMAND ${CMAKE_CTEST_COMMAND} -V
    DEPENDS sanity test_jump test_save test_load
    COMMENT "Running all tests (sanity and unit tests)"
)