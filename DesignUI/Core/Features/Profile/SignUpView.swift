import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSecured = true
    @State private var isConfirmSecured = true
    
    // Validation Error Messages
    @State private var emailError = ""
    @State private var passwordError = ""
    @State private var confirmPasswordError = ""
    
    // Add computed property to check if form is valid
    private var isFormValid: Bool {
        emailError.isEmpty && passwordError.isEmpty && confirmPasswordError.isEmpty &&
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Text("Create Account")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Sign up to get started")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Email/Password Fields
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .onChange(of: email) {
                                validateEmail()
                            }

                        if !emailError.isEmpty {
                            Text(emailError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 4) {
                        ZStack(alignment: .trailing) {
                            Group{
                                HStack {
                                    if isSecured {
                                        SecureField("Password", text: $password)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                            .textContentType(.newPassword)
                                            .onChange(of: password) {
                                                validatePassword()
                                            }
                                    } else {
                                        TextField("Password", text: $password)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                            .textContentType(.newPassword)
                                            .onChange(of: password) {
                                                validatePassword()
                                            }
                                    }
                                }
                                
                                Button {
                                    isSecured.toggle()
                                } label: {
                                    Image(systemName: isSecured ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                        .padding()
                                }
                            }
                        }
                        
                        if !passwordError.isEmpty {
                            Text(passwordError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 4) {
                        ZStack(alignment: .trailing) {
                            Group{
                                HStack {
                                    if isConfirmSecured {
                                        SecureField("Confirm Password", text: $confirmPassword)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                            .textContentType(.newPassword)
                                            .onChange(of: confirmPassword){
                                                validateConfirmPassword()
                                            }
                                    } else {
                                        TextField("Confirm Password", text: $confirmPassword)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                            .textContentType(.newPassword)
                                            .onChange(of: confirmPassword){
                                                validateConfirmPassword() }
                                    }
                                }
                                
                                Button {
                                    isConfirmSecured.toggle()
                                } label: {
                                    Image(systemName: isConfirmSecured ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                        .padding()
                                }
                            }
                        }
                        
                        if !confirmPasswordError.isEmpty {
                            Text(confirmPasswordError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Sign Up Button
                Button {
                    Task {
                        await signUp()
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isFormValid ? Color.blue : Color.blue.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(!isFormValid || authViewModel.isLoading)
                
                // Sign In Link
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .font(.footnote)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                    }
                }
            }
            .alert("Error", isPresented: $authViewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authViewModel.errorMessage)
            }
        }
    }
    
    // MARK: - Validation Functions
    
    private func validateEmail() {
        if email.isEmpty {
            emailError = "Email is required"
        } else if !email.contains("@") || !email.contains(".") {
            emailError = "Enter a valid email"
        } else {
            emailError = ""
        }
    }
    
    private func validatePassword() {
        if password.isEmpty {
            passwordError = "Password is required"
        } else if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
        } else {
            passwordError = ""
        }
    }
    
    private func validateConfirmPassword() {
        if confirmPassword.isEmpty {
            confirmPasswordError = "Please confirm your password"
        } else if confirmPassword != password {
            confirmPasswordError = "Passwords do not match"
        } else {
            confirmPasswordError = ""
        }
    }
    
    // MARK: - Sign Up Function
    private func signUp() async {
        guard isFormValid else { return }
        
        await authViewModel.signUp(email: email, password: password)
        
        // Only dismiss if sign up was successful
        if authViewModel.isAuthenticated {
            dismiss()
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
