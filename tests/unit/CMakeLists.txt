# tests/unit/CMakeLists.txt

# Add the unit test executables
add_executable(test_jump jump.c)
add_executable(test_save save.c)
add_executable(test_load load.c)
add_executable(test_strong_next strong_next.c)

# Link against the cromulent library
target_link_libraries(test_jump cromulent)
target_link_libraries(test_save cromulent)
target_link_libraries(test_load cromulent)
target_link_libraries(test_strong_next cromulent)

# Add the tests to CTest
add_test(NAME test_jump COMMAND test_jump)
add_test(NAME test_save COMMAND test_save)
add_test(NAME test_load COMMAND test_load)
add_test(NAME test_strong_next COMMAND test_strong_next)

# Create a "run_all_unit_tests" target
add_custom_target(run_all_unit_tests
    COMMAND ${CMAKE_CTEST_COMMAND} -V
    DEPENDS test_jump test_save test_load test_strong_next
    COMMENT "Running all unit tests"
)
