# Flutter wraps its own engine rules; these cover the plugins we ship.

# flutter_local_notifications keeps notification payload classes via reflection.
-keep class com.dexterous.** { *; }

# Drift / sqlite3_flutter_libs load the native library by name.
-keep class org.sqlite.** { *; }

# Stockfish is reached through FFI; the loader must survive shrinking.
-keep class com.example.stockfish.** { *; }

# Keep annotation attributes used by json_serializable-generated reflection-free
# code paths and by the Play Core split-install stubs Flutter references.
-keepattributes *Annotation*
-dontwarn com.google.android.play.core.**
