function(COPY_DEPENDENCIES)
    set(options "")
    set(oneValueArgs TARGET DESTINATION)
    set(multiValueArgs DEPENDENCY_PATTERNS)
    cmake_parse_arguments(IN "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

    file(GLOB DEPENDENCY_FILES ${IN_DEPENDENCY_PATTERNS})

    set(COPY_TARGETS "")

    foreach(DEPENDENCY_FILE ${DEPENDENCY_FILES})
        get_filename_component(CURRENT_TARGET ${DEPENDENCY_FILE} NAME_WE)
        add_custom_target(${CURRENT_TARGET}
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEPENDENCY_FILE}" "${IN_DESTINATION}")

        set(COPY_TARGETS ${COPY_TARGETS} ${CURRENT_TARGET})
    endforeach()

    add_dependencies(${IN_TARGET} ${COPY_TARGETS})
endfunction()

function(GENERATE_SORUCES_WITH_PREFIX)
    set(options "")
    set(oneValueArgs PREFIX OUT)
    set(multiValueArgs FILES)
    cmake_parse_arguments(IN "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

    set(SOURCE_FILES "")

    foreach(SOURCE_FILE ${IN_FILES})
        set(SOURCE_FILES "${SOURCE_FILES}" "${IN_PREFIX}/${SOURCE_FILE}")
    endforeach()

    set(${IN_OUT} "${SOURCE_FILES}" PARENT_SCOPE)
endfunction()

function(GENERATE_CONFIG)
    set(options HYPHEN_CASE CAMEL_CASE)
    set(oneValueArgs VERSION COMPATIBILITY OUT_NAME_PREFIX OUT_PATH_PREFIX OUT_TARGETS_FILE_SUFFIX IN_CONFIG_FILE NAMESPACE)
    set(multiValueArgs CONFIG_PARAMS EXPORT_TARGETS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

    if(ARG_HYPHEN_CAS AND ARG_CAMEL_CASE)
        message(FATAL_ERROR "In generate_config function you need set only one of options: HYPHEN_CASE or CAMEL_CASE, not both. HYPHEN_CASE by default")
    endif()

    #message("OUT_NAME_PREFIX         = ${ARG_OUT_NAME_PREFIX}")
    #message("OUT_PATH_PREFIX         = ${ARG_OUT_PATH_PREFIX}")
    #message("VERSION                 = ${ARG_VERSION}")
    #message("COMPATIBILITY           = ${ARG_COMPATIBILITY}")
    #message("IN_CONFIG_FILE          = ${ARG_IN_CONFIG_FILE}")
    #message("OUT_TARGETS_FILE_SUFFIX = ${ARG_OUT_TARGETS_FILE_SUFFIX}")
    #message("EXPORT_TARGETS          = ${ARG_EXPORT_TARGETS}")
    #message("NAMESPACE               = ${ARG_NAMESPACE}")
    #message("CONFIG_PARAMS           = ${ARG_CONFIG_PARAMS}")

    if(NOT ARG_OUT_NAME_PREFIX OR 
        NOT ARG_VERSION OR 
        NOT ARG_COMPATIBILITY OR 
        NOT ARG_IN_CONFIG_FILE OR 
        NOT ARG_EXPORT_TARGETS OR 
        NOT ARG_NAMESPACE)
        
        message(FATAL_ERROR "generate_config function required arguments: VERSION, COMPATIBILITY, OUT_NAME_PREFIX, IN_CONFIG_FILE, EXPORT_TARGETS, NAMESPACE")
    endif()

    if(ARG_HYPHEN_CASE)
        set(_TARGETS_POSTFIX "-targets")
        set(_CONFIG_POSTFIX "-config")
        set(_VERSION_POSTFIX "-config-version")
    elseif(ARG_CAMEL_CASE)
        set(_TARGETS_POSTFIX "Targets")
        set(_CONFIG_POSTFIX "Config")
        set(_VERSION_POSTFIX "ConfigVersion")
    endif()

    foreach(_CONFIG_PARAM "${ARG_CONFIG_PARAMS}")
        string(REGEX REPLACE "=.*$" "" _KEY "${_CONFIG_PARAM}")
        string(REGEX REPLACE "^.*=" "" _VALUE "${_CONFIG_PARAM}")

        set(${_KEY} "${_VALUE}")
    endforeach()
    
    install(
        EXPORT ${ARG_EXPORT_TARGETS}
        FILE "${ARG_OUT_NAME_PREFIX}${ARG_OUT_TARGETS_FILE_SUFFIX}${_TARGETS_POSTFIX}.cmake"
        NAMESPACE "${ARG_NAMESPACE}"
        DESTINATION "lib/cmake/${ARG_OUT_NAME_PREFIX}")

    # Create config version files
    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
        "${ARG_OUT_PATH_PREFIX}/${ARG_OUT_NAME_PREFIX}${_VERSION_POSTFIX}.cmake"
        VERSION "${ARG_VERSION}"
        COMPATIBILITY "${ARG_COMPATIBILITY}")

    # Create config file
    configure_file(
        "${ARG_IN_CONFIG_FILE}"
        "${ARG_OUT_PATH_PREFIX}/${ARG_OUT_NAME_PREFIX}${_CONFIG_POSTFIX}.cmake"
        @ONLY)

    # Install config file
    install(
        FILES 
            "${ARG_OUT_PATH_PREFIX}/${ARG_OUT_NAME_PREFIX}${_CONFIG_POSTFIX}.cmake"
            "${ARG_OUT_PATH_PREFIX}/${ARG_OUT_NAME_PREFIX}${_VERSION_POSTFIX}.cmake"
        DESTINATION "lib/cmake/${ARG_OUT_NAME_PREFIX}")
endfunction()