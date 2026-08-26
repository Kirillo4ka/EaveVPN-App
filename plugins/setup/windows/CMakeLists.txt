cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "setup")
project(${PROJECT_NAME} LANGUAGES CXX)

get_filename_component(PROJECT_ROOT "${CMAKE_SOURCE_DIR}" DIRECTORY)

set(setup_bundled_libraries
  "${PROJECT_ROOT}/libclash/windows/FlClashCore.exe"
  "${PROJECT_ROOT}/libclash/windows/FlClashHelperService.exe"
  "${PROJECT_ROOT}/libclash/windows/manifest.json"
  "${PROJECT_ROOT}/libclash/windows/EnableLoopback.exe"
  PARENT_SCOPE
)
