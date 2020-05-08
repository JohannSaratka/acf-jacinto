cmake_minimum_required(VERSION 2.8.12)
project(py-acf-toolbox)
#set(CMAKE_VERBOSE_MAKEFILE ON)

# Set source directory
set(SOURCE_DIR "channels/private")
# Tell CMake that headers are also in SOURCE_DIR
include_directories(${SOURCE_DIR})
set(SOURCES "${SOURCE_DIR}/chnsCellSumMex.cpp")

add_subdirectory(lib/pybind11)
pybind11_add_module(_channels ${SOURCES} "${SOURCE_DIR}/bindings.cpp")
