# Flutter bringt die Regeln für seine Engine selbst mit; hier steht, was die
# eingebundenen Plugins brauchen.

# flutter_local_notifications hält seine Nutzdaten-Klassen über Reflexion.
-keep class com.dexterous.** { *; }

# Drift und sqlite3_flutter_libs laden die native Bibliothek über ihren Namen.
-keep class org.sqlite.** { *; }

# flutter_secure_storage benutzt den Keystore über androidx.security.
-keep class androidx.security.crypto.** { *; }

# flutter_web_auth_2 nimmt die OAuth-Rückleitung in einer eigenen Activity an.
-keep class com.linusu.flutter_web_auth_2.** { *; }

# Anmerkungen bleiben erhalten; Play Core referenziert Flutter, ohne dass wir
# es einbinden.
-keepattributes *Annotation*
-dontwarn com.google.android.play.core.**
