//
//  DevicePickerView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 3/26/25.
//

import SwiftUI

struct DevicePickerView: View {
    @Binding var selectedDevice: DevicePreset
    
    let devices: [DevicePreset] = [
        DevicePreset(
            name: "iPhone 14 Pro",
            size: CGSize(width: 393, height: 852),
            cornerRadius: 55,
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
        ),
        DevicePreset(
            name: "iPhone 14 Pro Max",
            size: CGSize(width: 430, height: 932),
            cornerRadius: 55,
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
        ),
        DevicePreset(
            name: "iPhone 14",
            size: CGSize(width: 390, height: 844),
            cornerRadius: 47,
            safeAreaInsets: EdgeInsets(top: 47, leading: 0, bottom: 34, trailing: 0)
        ),
        DevicePreset(
            name: "iPhone SE (3rd gen)",
            size: CGSize(width: 375, height: 667),
            cornerRadius: 0,
            safeAreaInsets: EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0)
        ),
        DevicePreset(
            name: "iPad Pro 11\"",
            size: CGSize(width: 834, height: 1194),
            cornerRadius: 18,
            safeAreaInsets: EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 0)
        )
    ]
    
    var body: some View {
        Menu {
            ForEach(devices, id: \.name) { device in
                Button(action: {
                    selectedDevice = device
                }) {
                    HStack {
                        Text(device.name)
                        if device.name == selectedDevice.name {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "iphone")
                Text(selectedDevice.name)
                Image(systemName: "chevron.down")
                    .imageScale(.small)
            }
            .padding(8)
            .background(Color.gray)
            .cornerRadius(8)
        }
    }
}

#Preview {
    DevicePickerView(selectedDevice: .constant(
        DevicePreset(
            name: "iPhone 14 Pro",
            size: CGSize(width: 393, height: 852),
            cornerRadius: 55,
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
        )
    ))
}
