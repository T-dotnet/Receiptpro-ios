# Supabase Authentication Setup for iOS Dashboard Shell

## Integration Summary

Supabase authentication is integrated into the ios-dashboard-shell SwiftUI project. The integration includes:
- `SupabaseManager.swift`: Handles Supabase client setup and authentication logic (sign up, sign in, sign out, session persistence) with placeholder URL and API key.
- `LoginView.swift`: Provides a simple SwiftUI login screen for sign in/sign up, error display, and sign out.
- `ContentView.swift`: Gates the dashboard behind authentication, showing LoginView if not authenticated and the TabView dashboard if authenticated.

## How to Add the Supabase Swift SDK

1. Open your project in Xcode.
2. Go to **File > Add Packages...**
3. Enter the Supabase Swift SDK URL: `https://github.com/supabase/supabase-swift`
4. Select the latest version and add the package to your project.

## Configuration

You can now configure your Supabase URL and anon key in `SupabaseManager.swift`. The authentication UI will appear before the dashboard if the user is not signed in.

All updated files are located in `ios-dashboard-shell/`.