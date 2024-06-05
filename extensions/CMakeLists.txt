cmake_minimum_required(VERSION 3.13)
project(openchamp LANGUAGES CXX)

set(SOURCES
    src/register_types.cpp
    src/identifier.cpp
)

include_directories(include)

# Assuming godot-cpp is a CMake project in a subdirectory
add_subdirectory(godot-cpp)

add_library(openchamp SHARED ${SOURCES})

string(TOLOWER ${CMAKE_SYSTEM_NAME} SYSTEM_NAME_LOWER)
string(TOLOWER ${CMAKE_BUILD_TYPE} BUILD_TYPE_LOWER)
string(TOLOWER ${CMAKE_SYSTEM_PROCESSOR} SYSTEM_PROCESSOR_LOWER)

set_target_properties(openchamp PROPERTIES OUTPUT_NAME openchamp.${SYSTEM_NAME_LOWER}.template_${BUILD_TYPE_LOWER}.${SYSTEM_PROCESSOR_LOWER})
target_link_libraries(openchamp godot-cpp)

target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_17)

install(TARGETS openchamp DESTINATION ${CMAKE_SOURCE_DIR}/../bin)

# Assuming the dependency is a library target
add_library(openchamp_dep INTERFACE)
target_link_libraries(openchamp_dep INTERFACE openchamp)