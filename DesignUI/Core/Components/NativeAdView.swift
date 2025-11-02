//
//  NativeAdView.swift
//  DesignUI
//
//  Created by Assistant on 1/11/25.
//
#if os(iOS)
import SwiftUI

import GoogleMobileAds

struct NativeAdView: View {
    let adIdentifier: String
    @StateObject private var adManager = AdManager.shared
    @State private var nativeAd: NativeAd?
    
    var body: some View {
        Group {
            if let nativeAd = nativeAd {
                NativeAdContentView(nativeAd: nativeAd)
                    .frame(height: 420)
            } else {
                // Placeholder while ad loads - same height to prevent layout shifts
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 420)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
                    .onAppear {
                        loadAd()
                    }
                    .onChange(of: adManager.nativeAds[adIdentifier]) { _, newAd in
                        if let ad = newAd {
                            nativeAd = ad
                        }
                    }
            }
        }
    }
    
    private func loadAd() {
        // Check if ad already exists
        if let existingAd = adManager.getNativeAd(for: adIdentifier) {
            nativeAd = existingAd
        } else {
            // Load new ad
            adManager.loadNativeAd(for: adIdentifier)
            
            // Check again after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let ad = adManager.getNativeAd(for: adIdentifier) {
                    nativeAd = ad
                }
            }
        }
    }
}

struct NativeAdContentView: UIViewRepresentable {
    let nativeAd: NativeAd
    
    func makeUIView(context: Context) -> UIView {
        // Create a container view with visual separation
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = false // Allow shadow to show
        
        // Add visual separation: shadow/elevation (required by AdMob)
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 6
        containerView.layer.shadowOpacity = 0.15
        
        // Create inner container that will clip content
        let innerContainer = UIView()
        innerContainer.backgroundColor = .systemBackground
        innerContainer.layer.cornerRadius = 12
        innerContainer.clipsToBounds = true
        innerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(innerContainer)
        NSLayoutConstraint.activate([
            innerContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
            innerContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            innerContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            innerContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Add the native ad view to inner container
        #if canImport(GoogleMobileAds)
        // Use actual NativeAdView (UIKit class) if SDK is available
        // Note: Using fully qualified name to avoid conflict with SwiftUI NativeAdView struct
        let gadAdView = GoogleMobileAds.NativeAdView()
        innerContainer.addSubview(gadAdView)
        gadAdView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gadAdView.topAnchor.constraint(equalTo: innerContainer.topAnchor),
            gadAdView.leadingAnchor.constraint(equalTo: innerContainer.leadingAnchor),
            gadAdView.trailingAnchor.constraint(equalTo: innerContainer.trailingAnchor),
            gadAdView.bottomAnchor.constraint(equalTo: innerContainer.bottomAnchor)
        ])
        
        // Setup template and register with NativeAdView (UIKit)
        setupNativeAdTemplate(gadAdView, nativeAd: nativeAd)
        
        // Register the native ad - this enables click handling
        // This must be done AFTER all views are registered
        gadAdView.nativeAd = nativeAd
        #else
        // SDK not available - use as regular UIView
        let nativeAdView = UIView()
        innerContainer.addSubview(nativeAdView)
        nativeAdView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nativeAdView.topAnchor.constraint(equalTo: innerContainer.topAnchor),
            nativeAdView.leadingAnchor.constraint(equalTo: innerContainer.leadingAnchor),
            nativeAdView.trailingAnchor.constraint(equalTo: innerContainer.trailingAnchor),
            nativeAdView.bottomAnchor.constraint(equalTo: innerContainer.bottomAnchor)
        ])
        
        // Setup template with manual click handler
        setupNativeAdTemplate(nativeAdView, nativeAd: nativeAd)
        #endif
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update native ad when it changes
        #if canImport(GoogleMobileAds)
        // Find the NativeAdView (UIKit) in the view hierarchy
        func findNativeAdView(in view: UIView) -> GoogleMobileAds.NativeAdView? {
            if let gadView = view as? GoogleMobileAds.NativeAdView {
                return gadView
            }
            for subview in view.subviews {
                if let found = findNativeAdView(in: subview) {
                    return found
                }
            }
            return nil
        }
        
        if let nativeAdView = findNativeAdView(in: uiView) {
            nativeAdView.nativeAd = nativeAd
        }
        #endif
    }
    
    private func setupNativeAdTemplate(_ adView: UIView, nativeAd: NativeAd) {
        // AdMob Requirements:
        // 1. Ad Attribution - "Ad" badge at the top (minimum 15x15 pixels)
        // 2. AdChoices icon - SDK handles this, but we ensure visibility
        // 3. Visual separation - Add shadow/elevation
        // 4. Call to action button
        
        // Create "Ad" badge for attribution (required by AdMob)
        let adBadge = UILabel()
        adBadge.text = "Advertisment"
        adBadge.font = .systemFont(ofSize: 12, weight: .semibold)
        adBadge.textColor = .label
        adBadge.textAlignment = .center
        adBadge.clipsToBounds = true
        adBadge.translatesAutoresizingMaskIntoConstraints = false
        
        // Visual separation: Add shadow/elevation to distinguish from content
        adView.layer.shadowColor = UIColor.black.cgColor
        adView.layer.shadowOffset = CGSize(width: 0, height: 2)
        adView.layer.shadowRadius = 4
        adView.layer.shadowOpacity = 0.1
        adView.backgroundColor = .systemBackground
        adView.layer.cornerRadius = 12
        adView.layer.masksToBounds = false
        
        // Create labels and image views
        let headlineLabel = UILabel()
        headlineLabel.text = nativeAd.headline
        headlineLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        headlineLabel.numberOfLines = 2
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let bodyLabel = UILabel()
        bodyLabel.text = nativeAd.body
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0 // Allow unlimited lines to prevent text cutoff
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = UIImageView()
        if let icon = nativeAd.icon?.image {
            iconView.image = icon
        }
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 12
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Use MediaView for main image/video asset (required by AdMob)
        #if canImport(GoogleMobileAds)
        let mediaView = GoogleMobileAds.MediaView()
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = 8
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        // MediaView automatically loads the image/video from the native ad
        #else
        // Fallback for when SDK is not available
        let imageView = UIImageView()
        if let image = nativeAd.images?.first?.image {
            imageView.image = image
        }
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        #endif
        
        // Call to action button (required by AdMob)
        // Note: Do NOT add gesture recognizers or manually enable/disable user interactions
        // AdMob will automatically manage userInteractionEnabled when the view is registered
        let callToActionButton = UIButton(type: .system)
        callToActionButton.setTitle(nativeAd.callToAction ?? "Learn More", for: .normal)
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        callToActionButton.backgroundColor = .systemBlue
        callToActionButton.setTitleColor(.white, for: .normal)
        callToActionButton.layer.cornerRadius = 8
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        // Don't set isUserInteractionEnabled here - AdMob manages this automatically
        
        // AdChoices view (required by AdMob - shows in top-right corner)
        #if canImport(GoogleMobileAds)
        let adChoicesView = GoogleMobileAds.AdChoicesView()
        adChoicesView.translatesAutoresizingMaskIntoConstraints = false
        #endif
        
        // Add views to ad view (Ad badge first, at the top)
        adView.addSubview(adBadge)
        adView.addSubview(iconView)
        adView.addSubview(headlineLabel)
        adView.addSubview(bodyLabel)
        #if canImport(GoogleMobileAds)
        adView.addSubview(mediaView)
        adView.addSubview(adChoicesView) // Add AdChoices view
        #else
        adView.addSubview(imageView)
        #endif
        adView.addSubview(callToActionButton)
        
        // Set up constraints
        var constraints: [NSLayoutConstraint] = [
            // Ad badge at top (minimum 15x15 pixels as required)
            adBadge.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
            adBadge.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            adBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20), // Minimum 15x15, using 20x20
            adBadge.heightAnchor.constraint(equalToConstant: 20),
            
            // Icon below ad badge
            iconView.topAnchor.constraint(equalTo: adBadge.bottomAnchor, constant: 8),
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            // Headline next to icon
            headlineLabel.topAnchor.constraint(equalTo: adBadge.bottomAnchor, constant: 8),
            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            headlineLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            
            // Body below headline
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            bodyLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
        ]
        
        // AdChoices view in top-right corner (required by AdMob)
        #if canImport(GoogleMobileAds)
        constraints.append(contentsOf: [
            adChoicesView.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
            adChoicesView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            adChoicesView.widthAnchor.constraint(greaterThanOrEqualToConstant: 20), // Minimum 15x15
            adChoicesView.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
        ])
        #endif
        
        // Media view (main image/video) below body - conditionally add constraints
        #if canImport(GoogleMobileAds)
        constraints.append(contentsOf: [
            mediaView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 12),
            mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            mediaView.heightAnchor.constraint(equalToConstant: 180),
            
            // Call to action button at bottom
            callToActionButton.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 12),
        ])
        #else
        constraints.append(contentsOf: [
            imageView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            imageView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            imageView.heightAnchor.constraint(equalToConstant: 180),
            
            // Call to action button at bottom
            callToActionButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
        ])
        #endif
        
        // Common CTA button constraints
        constraints.append(contentsOf: [
            callToActionButton.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            callToActionButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            callToActionButton.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -12),
            callToActionButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        NSLayoutConstraint.activate(constraints)
        
        // Register views with the native ad for AdMob to handle clicks
        // Register with AdMob SDK - this enables automatic click handling
        // IMPORTANT: When views are registered, AdMob automatically:
        // - Sets userInteractionEnabled = NO on asset views (this is expected and required)
        // - Adds its own gesture recognizers to handle clicks
        // - Manages all click tracking and attribution
        // The console message about userInteractionEnabled being set to NO is expected behavior.
        if let gadAdView = adView as? GoogleMobileAds.NativeAdView {
            // Register all asset views with AdMob - this is required for clicks to work
            gadAdView.headlineView = headlineLabel
            gadAdView.bodyView = bodyLabel
            gadAdView.iconView = iconView
            gadAdView.mediaView = mediaView // Use MediaView instead of imageView (required by AdMob)
            gadAdView.callToActionView = callToActionButton
            gadAdView.adChoicesView = adChoicesView // Register AdChoices view (required by AdMob)
            // Set the native ad - this activates AdMob's click handling and populates AdChoices
            // After this line, AdMob will disable user interactions on asset views and handle all clicks
            gadAdView.nativeAd = nativeAd
            // AdMob will now handle all click interactions automatically through its own gesture recognizers
        }
    }
}
#endif
