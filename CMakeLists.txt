cmake_minimum_required(VERSION 3.15)

project(hello_conan_cmake VERSION 0.1.0)

add_executable(hello_conan_cmake)

find_package(fmt CONFIG REQUIRED)
find_package(libsodium CONFIG REQUIRED)

target_sources(hello_conan_cmake PRIVATE main.cpp)
target_link_libraries(hello_conan_cmake PRIVATE fmt::fmt libsodium::libsodium)