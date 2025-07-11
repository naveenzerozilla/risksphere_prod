# Fully ignore Push Provisioning classes from Stripe (they don't exist)
-assumenosideeffects class com.stripe.android.pushProvisioning.** { *; }
-assumenosideeffects class com.reactnativestripesdk.pushprovisioning.** { *; }

-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**