cmake_minimum_required(VERSION 3.15)
project(verovio_flutter VERSION 0.0.1 LANGUAGES CXX)

# C++17 standard for compatibility (C++20 needed for full Verovio but causes issues)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Simple approach - create a working hybrid wrapper
add_library(verovio_flutter SHARED
    ${CMAKE_SOURCE_DIR}/../../../../src/verovio_flutter.cpp
)

# Set basic properties
set_target_properties(verovio_flutter PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
)

# Basic definitions
target_compile_definitions(verovio_flutter PRIVATE
    DART_SHARED_LIB
    ANDROID
    VEROVIO_HYBRID_WRAPPER
)

# Include basic directories
target_include_directories(verovio_flutter PRIVATE
    ${CMAKE_SOURCE_DIR}/../../../../src
)

# Link with basic libraries only
find_library(log-lib log)
target_link_libraries(verovio_flutter ${log-lib})

# TODO: Future Verovio integration notes
# When ready to implement full Verovio, uncomment and fix C++20 compatibility:
#
# include_directories(
#     ${CMAKE_SOURCE_DIR}/../../../../verovio/include
#     ${CMAKE_SOURCE_DIR}/../../../../verovio/tools
# )
#
# file(GLOB verovio_SRC "${CMAKE_SOURCE_DIR}/../../../../verovio/src/*.cpp")
# target_sources(verovio_flutter PRIVATE ${verovio_SRC})