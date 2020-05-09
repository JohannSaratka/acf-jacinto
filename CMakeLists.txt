cmake_minimum_required(VERSION 3.12)
project(py-acf-toolbox)
#set(CMAKE_VERBOSE_MAKEFILE ON)

# Set source directory

set(SOURCE_DIR "channels/private")
# Tell CMake that headers are also in SOURCE_DIR
include_directories(${SOURCE_DIR})
include(${SOURCE_DIR}/CMakeLists.txt)

add_subdirectory(lib/pybind11)
pybind11_add_module(_channels ${SOURCES} "${SOURCE_DIR}/bindings.cpp")
