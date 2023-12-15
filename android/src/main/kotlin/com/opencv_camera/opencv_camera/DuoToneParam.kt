package com.opencv_camera.opencv_camera

data class DuoToneParam(
    val exponent: Int,
    val s1: Int, // value from 0-2 (0 : BLUE n1 : GREEN n2 : RED)
    val s2: Int, // value from 0-3 (0 : BLUE n1 : GREEN n2 : RED n3 : NONE)
    val s3: Int, // (0 : DARK n1 : LIGHT)
)
