
list(APPEND SOURCES
    chnsCellSumMex.cpp
    imPadMex.cpp
    rgbConvertMex.cpp
)
list(TRANSFORM SOURCES PREPEND ${CMAKE_CURRENT_LIST_DIR}/)