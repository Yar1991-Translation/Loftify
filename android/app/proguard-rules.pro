# ProGuard/R8 rules for release builds (referenced by android/app/build.gradle).
# Keep this file minimal: the Flutter engine and plugins ship their own consumer
# rules; only add project-specific keep rules here.

# Flutter embedding classes are resolved reflectively.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
