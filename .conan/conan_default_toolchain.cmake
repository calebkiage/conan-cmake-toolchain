# Check for a conanfile before doing any processing. Prevents running the conan
# logic in directories with no conan files. Fixes issues with importing during
# cmake's compiler detection steps
find_file(CONAN_FILE_PATH NAMES conanfile.py conanfile.txt PATHS ${CMAKE_SOURCE_DIR} NO_DEFAULT_PATH)

if (NOT CONAN_FILE_PATH)
  return()
endif ()

set(_conan_install_dir "${CMAKE_BINARY_DIR}/conan-install")

function(_get_install_args)
  set(optionArgs "")
  set(oneValueArgs "BUILD_TYPE;OUTPUT_VARIABLE")
  set(miltiValueArgs "")

  cmake_parse_arguments(_ARG "${optionsArgs}" "${oneValueArgs}" "${miltiValueArgs}" ${ARGV})

  string(STRIP "${_ARG_BUILD_TYPE}" _build_type)

  # Recipes fail if build type is None
  if (NOT _build_type)
    message(FATAL_ERROR "Build type should be defined")
  endif ()

  set(conan_install_args "")

  # Use new conan cmake generators.
  list(APPEND conan_install_args install ${CMAKE_SOURCE_DIR} --install-folder ${_conan_install_dir})

  if (BUILD_SHARED_LIBS)
    set(conan_install_args "${conan_install_args};--options:host;build_shared=True")
  endif ()

  if (CONAN_FORCE_BUILD_PACKAGES)
    foreach (_package ${CONAN_FORCE_BUILD_PACKAGES})
      # Build * if you want to debug
      list(APPEND conan_install_args --build=${_package})
    endforeach ()
  endif ()
  list(APPEND conan_install_args --build missing)

  if (CMAKE_GENERATOR)
    list(APPEND conan_install_args "--conf:host" "tools.cmake.cmaketoolchain:generator=${CMAKE_GENERATOR}")
  endif ()

  set(machine_types "host;build")

  foreach (type ${machine_types})
    string(TOLOWER ${type} type_lower)
    string(TOUPPER ${type} type_upper)

    set(options "profile;settings;conf")

    foreach (op ${options})
      string(TOLOWER ${op} op_lower)
      string(TOUPPER ${op} op_upper)

      # Allow setting options for conan in CMake. They use the form: 
      # CONAN_{HOST|BUILD}_{PROFILE|SETTINGS|CONF}
      # Example: CONAN_HOST_PROFILE in CMakePresets.json
      if (CONAN_${type_upper}_${op_upper})
        list(APPEND conan_install_args --${op_lower}:${type_lower} ${CONAN_${type_upper}_${op_upper}})
      endif ()
    endforeach ()
  endforeach ()

  # Set the build type based on CMake options
  list(APPEND conan_install_args "--settings:build" "build_type=${_build_type}" "--settings:host" "build_type=${_build_type}")

  # TODO: Is it better to run conan show profile to get the compiler name?
  if ("${CMAKE_GENERATOR}" MATCHES "Visual Studio.*")
    if ("${_build_type}" STREQUAL "Debug")
      set(conan_install_args "${conan_install_args};--settings:build;compiler.runtime_type=Debug")
      set(conan_install_args "${conan_install_args};--settings:host;compiler.runtime_type=Debug")
    endif ()
  endif ()

  set(${_ARG_OUTPUT_VARIABLE} "${conan_install_args}" PARENT_SCOPE)
endfunction()

function(_get_checksum_file_path file output_var)
  set(_file_name_var "_file_name")
  if (${CMAKE_VERSION} GREATER_EQUAL "3.20")
    cmake_path(GET file FILENAME "${_file_name_var}")
  else ()
    get_filename_component("${_file_name_var}" "${file}" NAME)
  endif ()

  set("${output_var}" "${_conan_install_dir}/${${_file_name_var}}.sha256.txt" PARENT_SCOPE)
endfunction()

function(_verify_checksum file output_var)
  set("${output_var}" "FALSE" PARENT_SCOPE)

  _get_checksum_file_path(${file} _file_checksum_path)

  if (NOT EXISTS "${file}" OR NOT EXISTS "${_file_checksum_path}")
    return()
  endif ()

  file(SHA256 ${file} _file_sum1)
  file(READ ${_file_checksum_path} _file_sum2)

  if ("${_file_sum1}" STREQUAL "${_file_sum2}")
    set(${output_var} "TRUE" PARENT_SCOPE)
  endif ()
endfunction()

function(_save_checksum file)
  _get_checksum_file_path(${file} _file_checksum_path)

  file(SHA256 ${file} _file_sum1)
  if (EXISTS "${_file_checksum_path}")
    file(READ ${_file_checksum_path} _file_sum2)
  endif()
  if (NOT "${_file_sum1}" STREQUAL "${_file_sum2}")
    file(WRITE "${_file_checksum_path}" ${_file_sum1})
    message(STATUS "Updated conanfile checksum.")
  endif ()
endfunction()

function(enable_conan)
  # Check for conan
  find_program(CONAN_PATH conan REQUIRED)

  if (NOT CONAN_FORCE_INSTALL)
    _verify_checksum(${CONAN_FILE_PATH} _is_valid)
    if (_is_valid)
      message(STATUS "Conan file unchanged. Skipping conan install")
      return()
    endif ()
  endif ()

  get_property(is_multi GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

  if (is_multi)
    foreach (type ${CMAKE_CONFIGURATION_TYPES})
      _get_install_args(BUILD_TYPE "${type}" OUTPUT_VARIABLE conan_install_args)

      # message("\nCommand: ${CONAN_PATH} ${conan_install_args}\n\n")
      execute_process(COMMAND ${CONAN_PATH} ${conan_install_args} RESULT_VARIABLE _result)
      if (NOT ${_result} EQUAL 0)
        # Exit early on the first error
        return()
      endif()
    endforeach ()
  else ()
    if (CMAKE_BUILD_TYPE)
      _get_install_args(BUILD_TYPE "${CMAKE_BUILD_TYPE}" OUTPUT_VARIABLE conan_install_args)
    else ()
      message(FATAL_ERROR "No CMake build type specified.\nPlease set a build type\ne.g.-DCMAKE_BUILD_TYPE=Release\n")
    endif ()
    # message("\nCommand: ${CONAN_PATH} ${conan_install_args}\n\n")
    execute_process(COMMAND ${CONAN_PATH} ${conan_install_args} RESULT_VARIABLE _result)
    if (NOT ${_result} EQUAL 0)
      return()
    endif()
  endif ()
  
  # Save the conan file checksum. If an error occurs, this function shouldn't be called.
  _save_checksum(${CONAN_FILE_PATH})
endfunction()

enable_conan()

set(_toolchain_path "${_conan_install_dir}/conan_toolchain.cmake")

unset(_conan_install_dir)

if (EXISTS "${_toolchain_path}")
  include("${_toolchain_path}")
else ()
  set(_error "\nConan generated CMake toolchain file not found.\nSearched location:")
  file(REAL_PATH "${_toolchain_path}" _real_toolchain EXPAND_TILDE)
  string(APPEND _error "\n${_real_toolchain}")
  message(WARNING "${_error}")
  unset(_error)
  unset(_real_toolchain)
endif ()
