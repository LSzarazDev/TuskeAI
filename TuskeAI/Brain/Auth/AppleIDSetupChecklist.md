# Apple ID + iCloud setup checklist

## Required Apple Developer configuration

1. Sign in to App Store Connect / Apple Developer.
2. Create or select the app bundle ID: `com.szarazlorant.TuskeAI` or the actual app ID used in Xcode.
3. Enable:
   - Sign in with Apple
   - CloudKit
4. Create or select the CloudKit container matching the app bundle identifier.
5. In Xcode:
   - set the Signing & Capabilities
   - add Sign in with Apple capability
   - add iCloud capability with CloudKit enabled
6. Ensure the project bundle identifier matches the Apple Developer configuration exactly.

## Current project state

- The app includes the entitlement file with Apple Sign In + CloudKit support.
- The app includes a basic Apple ID login manager.
- The app includes a CloudKit sync manager for model profiles.

## Important

The code is ready, but the real device/test flow requires the Apple Developer account and provisioning profile to be configured in Xcode.
