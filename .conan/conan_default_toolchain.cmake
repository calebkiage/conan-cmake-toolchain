
function(get_install_args build_type out_var)
    set(conan_install_args "")
    list(APPEND conan_install_args install ${CMAKE_SOURCE_DIR} --generator CMakeDeps --generator CMakeToolchain --build missing --update)

    if(CMAKE_GENERATOR)
        list(APPEND conan_install_args "--conf:host" "tools.cmake.cmaketoolchain:generator=${CMAKE_GENERATOR}")
        message(NOTICE "Set cmake generator")
    endif()

    set(machine_types "host;build")

    foreach(type ${machine_types})
        string(TOLOWER ${type} type_lower)
        string(TOUPPER ${type} type_upper)

        set(options "profile;settings;conf")

        foreach(op ${options})
            string(TOLOWER ${op} op_lower)
            string(TOUPPER ${op} op_upper)
            if(CONAN_${type_upper}_${op_upper})
                list(APPEND conan_install_args --${op_lower}:${type_lower} ${CONAN_${type_upper}_${op_upper}})
            endif()
        endforeach()
    endforeach()
    # "--settings:build" "build_type=${type}" "--settings:host" "build_type=${type}"
    list(APPEND conan_install_args "--settings:build" "build_type=${build_type}" "--settings:host" "build_type=${build_type}")

    if("${CMAKE_GENERATOR}" MATCHES "Visual Studio.*")
        if ("${build_type}" STREQUAL "Debug" OR "${build_type}" STREQUAL "RelWithDebInfo")
            set(conan_install_args "${conan_install_args};--settings:build;compiler.runtime_type=Debug")
            set(conan_install_args "${conan_install_args};--settings:host;compiler.runtime_type=Debug")
        endif()
        if (BUILD_SHARED_LIBS)
            if("${build_type}" STREQUAL "DEBUG")
                set(conan_install_args "${conan_install_args};--settings:host;compiler.runtime=MDd")
            else()
                set(conan_install_args "${conan_install_args};--settings:host;compiler.runtime=MD")
            endif()
        else()
            if("${build_type}" STREQUAL "DEBUG")
                set(conan_install_args "${conan_install_args};--settings:host;compiler.runtime=MTd")
            else()
                set(conan_install_args "${conan_install_args};--settings:host;compiler.runtime=MT")
            endif()
        endif()
    endif()
    

    set(${out_var} "${conan_install_args}" PARENT_SCOPE)
endfunction()

function(enable_conan)
    find_file(CONAN_FILE_PATH NAMES conanfile.py conanfile.txt PATHS ${CMAKE_SOURCE_DIR} NO_DEFAULT_PATH)

    if (NOT CONAN_FILE_PATH)
        return()
    endif()

    find_program(CONAN_PATH conan REQUIRED)

    get_property(is_multi GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

    if (is_multi AND CMAKE_CONFIGURATION_TYPES)
        foreach (type ${CMAKE_CONFIGURATION_TYPES})
            get_install_args("${type}" conan_install_args)
            
            message("\n\nCommand: ${CONAN_PATH} ${conan_install_args};--build_type;${type}\n\n")
            execute_process(COMMAND ${CONAN_PATH} ${conan_install_args})
        endforeach ()
    else ()
        if(CMAKE_BUILD_TYPE)
            get_install_args("${CMAKE_BUILD_TYPE}" conan_install_args)
            message("\n\nCommand: ${CONAN_PATH} ${conan_install_args}\n\n")
            execute_process(COMMAND ${CONAN_PATH} ${conan_install_args})
        else()
            message(FATAL_ERROR "Build type should be defined")
        endif()
    endif ()
endfunction()

enable_conan()

if(EXISTS ${CONAN_TOOLCHAIN_FILE})
    include("${CONAN_TOOLCHAIN_FILE}")
endif()
