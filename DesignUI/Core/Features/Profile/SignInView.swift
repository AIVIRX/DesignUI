import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var isSecured = true
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
    @State private var signInAppleButtonId = UUID().uuidString
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Text("Welcome Back")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Sign in with Apple button
                SignInWithAppleButton { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    Task {
                        await authViewModel.handleSignInWithApple(result)
                    }
                }
                .id(signInAppleButtonId)
                .signInWithAppleButtonStyle(
                    colorScheme == .dark ? .white : .black
                )
                .onChange(of: colorScheme, { oldValue, newValue in
                        signInAppleButtonId = UUID().uuidString
                    })
                .frame(height: 50)
                .cornerRadius(12)
                
                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("or")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                }
                
                // Email/Password Fields
                VStack(spacing: 16) {
                    // Email Field
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    // Password Field
                    ZStack(alignment: .trailing) {
                        Group{
                            if isSecured {
                                SecureField("Password", text: $password)
                                    .textFieldStyle(RoundedTextFieldStyle())
                                    .textContentType(.password)
                            } else {
                                TextField("Password", text: $password)
                                    .textFieldStyle(RoundedTextFieldStyle())
                                    .textContentType(.password)
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
                
                // Forgot Password
                Button {
                    showForgotPassword = true
                } label: {
                    Text("Forgot Password?")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                // Sign In Button
                Button {
                    Task {
                        await authViewModel.signIn(email: email, password: password)
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(authViewModel.isLoading)
                
                // Sign Up Link
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundColor(.gray)
                    
                    Button {
                        showSignUp = true
                    } label: {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .font(.footnote)
                .sheet(isPresented: $showSignUp) {
                    SignUpView()
                        .environmentObject(authViewModel)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authViewModel.errorMessage)
        }
    }
}

// Custom Text Field Style
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
    }
}

// Preview
#Preview {
    SignInView()
} 
