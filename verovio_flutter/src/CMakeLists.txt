# FASE 2.3: Build Cross-Platform - Configuração CMake básica para teste FFI
# Flutter tooling requires CMake 3.10 or later
cmake_minimum_required(VERSION 3.10)

# Projeto com C++17 support (mais compatível)
project(verovio_flutter_library VERSION 0.0.1 LANGUAGES CXX)

# C++17 standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Plugin principal (apenas nosso código por enquanto)
add_library(verovio_flutter SHARED
    "verovio_flutter.cpp"
)

# Propriedades do target
set_target_properties(verovio_flutter PROPERTIES
    PUBLIC_HEADER verovio_flutter.h
    OUTPUT_NAME "verovio_flutter"
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
)

# Definições de compilação
target_compile_definitions(verovio_flutter PUBLIC DART_SHARED_LIB)

# Flags específicas do Verovio
target_compile_definitions(verovio_flutter PRIVATE
    VRV_NO_HUMDRUM_SUPPORT      # Desabilitar Humdrum se não necessário
    VRV_FULL_SUPPORT            # Support completo do Verovio
)

# Otimizações para performance
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_options(verovio_flutter PRIVATE
        $<$<COMPILE_LANGUAGE:CXX>:-O3>
        $<$<COMPILE_LANGUAGE:CXX>:-ffast-math>
        $<$<COMPILE_LANGUAGE:CXX>:-DNDEBUG>
    )
endif()

# Configurações específicas para Android
if (ANDROID)
    # Support Android 15 16k page size
    target_link_options(verovio_flutter PRIVATE "-Wl,-z,max-page-size=16384")

    # Link com libraries do Android
    target_link_libraries(verovio_flutter
        android
        log
    )
endif()

# Configurações para iOS
if (IOS)
    set_target_properties(verovio_flutter PROPERTIES
        FRAMEWORK TRUE
        FRAMEWORK_VERSION A
        MACOSX_FRAMEWORK_IDENTIFIER com.musilingo.verovio_flutter
    )
endif()

# Configurações para Windows
if (WIN32)
    target_compile_definitions(verovio_flutter PRIVATE
        WIN32_LEAN_AND_MEAN
        NOMINMAX
    )
endif()

# Link com pthread para threading support
find_package(Threads REQUIRED)
target_link_libraries(verovio_flutter Threads::Threads)
