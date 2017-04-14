cmake_minimum_required(VERSION 2.6)
project(LIBUECC C)
set(PROJECT_VERSION 7)

set(CMAKE_MODULE_PATH ${LIBUECC_SOURCE_DIR})

set(DOXYFILE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")
set(DOXYFILE_EXTRA_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/include")

include(UseDoxygen OPTIONAL)

set(LIBDIR "lib${LIB_SUFFIX}")

add_subdirectory(src)

configure_file(${LIBUECC_SOURCE_DIR}/libuecc.pc.in ${LIBUECC_BINARY_DIR}/libuecc.pc @ONLY)
install(FILES ${LIBUECC_BINARY_DIR}/libuecc.pc DESTINATION "${LIBDIR}/pkgconfig")

FILE(GLOB include_files "${CMAKE_CURRENT_SOURCE_DIR}/include/libuecc/*.h")
install(FILES ${include_files} DESTINATION "include/libuecc-${PROJECT_VERSION}/libuecc")
