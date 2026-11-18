cmake_minimum_required(VERSION 3.22)
project(cpp_boost_bench LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Boost REQUIRED COMPONENTS filesystem program_options)
find_package(SDL2 REQUIRED)
find_package(GLEW REQUIRED)
find_package(OpenAL REQUIRED)
find_package(Freetype REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(VORBIS REQUIRED IMPORTED_TARGET vorbis)

add_executable(bench src/main.cpp)
target_include_directories(bench PRIVATE ${OPENAL_INCLUDE_DIR})
target_link_libraries(bench PRIVATE
  Boost::filesystem Boost::program_options
  SDL2::SDL2 GLEW::GLEW ${OPENAL_LIBRARY} Freetype::Freetype PkgConfig::VORBIS)

enable_testing()
add_test(NAME self-test COMMAND bench --self-test)
