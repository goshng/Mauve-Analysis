cmake_minimum_required (VERSION 2.8.3) 
project (ExSequence)
include_directories (/Users/goshng/usr/include /Users/goshng/usr/include/Bpp)
link_directories (/Users/goshng/usr/lib)

SET (CMAKE_CXX_FLAGS_DEBUG "-O0 -ggdb -g3")
add_executable (ExSequence ExSequence.cpp)
target_link_libraries (ExSequence bpp-core bpp-seq)

add_executable (test_containers test_containers.cpp)
target_link_libraries (test_containers bpp-core bpp-seq)

add_executable (test_io test_io.cpp)
target_link_libraries (test_io bpp-core bpp-seq)

add_executable (test_alphabets test_alphabets.cpp)
target_link_libraries (test_alphabets bpp-core bpp-seq)

add_executable (compute_watterson_estimate compute_watterson_estimate.cpp)
target_link_libraries (compute_watterson_estimate bpp-core bpp-seq)



