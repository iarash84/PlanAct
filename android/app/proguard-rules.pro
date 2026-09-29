# Flutter and plugin entry points are discovered by Android/plugin registries.
-keep class io.flutter.** { *; }
-keep class com.example.planact.BankSmsReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Flutter's Android embedding references Play Store deferred-component APIs.
# PlanAct does not use deferred components, so these optional references may be
# absent from the release classpath without preventing R8 optimization.
-dontwarn com.google.android.play.core.**
