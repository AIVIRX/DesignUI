//
//  AnimatedImageView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 4/29/24.
//

import SwiftUI
import WebKit

struct GIFView: UIViewRepresentable {
    let gifName: String
    let webView = WKWebView()

    func makeUIView(context: Context) -> WKWebView {
        guard let gifURL = Bundle.main.url(forResource: gifName, withExtension: "gif") else {
            fatalError("Failed to find GIF file: \(gifName).gif")
        }
        let request = URLRequest(url: gifURL)
        webView.load(request)
        webView.contentMode = .scaleAspectFill
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}
