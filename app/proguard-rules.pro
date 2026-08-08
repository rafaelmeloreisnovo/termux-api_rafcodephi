# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in android-sdk/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

-dontobfuscate

# Guava's J2ObjC ownership annotation is class-retained metadata and is not
# required by the Android runtime. Keep the suppression narrow so other
# genuinely missing classes still fail the release build.
-dontwarn com.google.j2objc.annotations.RetainedWith
