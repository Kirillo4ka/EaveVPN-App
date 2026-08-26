cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "rust_api")
project(${PROJECT_NAME} LANGUAGES CXX)

get_filename_component(PROJECT_ROOT "${CMAKE_SOURCE_DIR}" DIRECTORY)

set(rust_api_bundled_libraries
  "${PROJECT_ROOT}/libclash/windows/rust_api.dll"
  PARENT_SCOPE
)
