//  LoginView.swift
//  ios-dashboard-shell

import SwiftUI

struct LoginView: View {
    @ObservedObject var supabase = SupabaseManager.shared

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Text(isSignUp ? "Sign Up" : "Sign In")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            if let error = supabase.authError {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: {
                if isSignUp {
                    supabase.signUp(email: email, password: password)
                } else {
                    supabase.signIn(email: email, password: password)
                }
            }) {
                Text(isSignUp ? "Sign Up" : "Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            Button(action: {
                isSignUp.toggle()
            }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.footnote)
            }

            if supabase.isAuthenticated {
                Button(action: {
                    supabase.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
                .padding(.top, 16)
            }
        }
        .padding()
    }
}