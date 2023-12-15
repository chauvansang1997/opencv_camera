cmake_minimum_required(VERSION 3.4.1)

set(CPP_ROOT ./)
set(OPEN_CV_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../../opencvsdk480)
include_directories(${CPP_ROOT}/general)

set(SRC_FILES
        ./general/general_funtion.h
        ./general/general_funtion.cpp
        ./native_opencv.cpp
        )

add_library(native-lib SHARED ${SRC_FILES})

include_directories(${OPEN_CV_PATH}/native/jni/include)
add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${OPEN_CV_PATH}/native/libs/${ANDROID_ABI}/libopencv_java4.so)

target_link_libraries(native-lib ${log-lib} ${android-lib})
# Link libraries
target_link_libraries(native-lib
                      z
                      lib_opencv
                      android
                      jnigraphics
                      log)
