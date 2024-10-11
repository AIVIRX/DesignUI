//
//  Supabase.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 10/10/24.
//


import Supabase
import SwiftUI

let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://dwxfipenxnqkhgtwggrv.supabase.co")!,
  supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3eGZpcGVueG5xa2hndHdnZ3J2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjgwNjU4OTMsImV4cCI6MjA0MzY0MTg5M30.0mg37FPNXhj0drM0TFSlSzpl2Ofc7nyaHqOTnobvjac"
)
