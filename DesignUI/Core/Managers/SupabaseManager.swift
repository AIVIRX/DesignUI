//
//  SupabaseInit.swift
//
//  Created by Maicol Cabreja on 10/12/24.
//

import SwiftUI
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient
    let supabaseURL: URL
    let supabaseKey: String
    
    private init() {
        supabaseURL = URL(string: "https://dwxfipenxnqkhgtwggrv.supabase.co")!
        supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3eGZpcGVueG5xa2hndHdnZ3J2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjgwNjU4OTMsImV4cCI6MjA0MzY0MTg5M30.0mg37FPNXhj0drM0TFSlSzpl2Ofc7nyaHqOTnobvjac"
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                auth: .init(
                    storage: KeychainLocalStorage(service: "com.Maicol.Dockui"),
                    flowType: .pkce,
                    autoRefreshToken: true,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
