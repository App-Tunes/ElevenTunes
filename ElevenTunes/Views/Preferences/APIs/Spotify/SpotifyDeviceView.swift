//
//  SpotifyDeviceView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.12.20.
//

import SwiftUI
import Combine
import SpotifyWebAPI

struct SpotifyDeviceView: View {
    @State var device: Device
    @State var isOnline: Bool
    @Binding var isSelected: Bool
    @Environment(\.isEnabled) var isEnabled: Bool
    
    var body: some View {
        HStack {
            Toggle("", isOn: $isSelected)

            Text(device.name)
                .foregroundColor(isEnabled ? Color.primary : Color.gray)

            Spacer()
            
            Image(systemName: "circle.fill")
                .foregroundColor(isOnline ? .green : .red)
        }
    }
}

struct SpotifyDevicesView: View {
    @ObservedObject var devices: SpotifyDevices
    
    @State var selected: Device?
    @State var rotation: Double = 0

    init(devices: SpotifyDevices) {
        self.devices = devices
    }
    
    var header: some View {
        HStack {
            Text("Devices")
            
            Button(action: {
                devices.query()
                withAnimation(.easeInOut(duration: 1)) {
                    rotation += 360  // This totally never overflows lol
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(rotation), anchor: .center)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
    var body: some View {
        Section(header: header) {
            HStack {
//                Toggle("Remember all devices", isOn: $devices.rememberAllDevices)
//                    .padding(.trailing)
                Toggle("Always Play on favorite", isOn: $devices.alwaysPlayOnFavorite)
                    .help("Try to always play here - even when the device is not marked as 'online'. This may wake the device up if it is not active.")
            }
            
            List(selection: $selected) {
                ForEach(devices.all, id: \.id) { device in
                    SpotifyDeviceView(device: device, isOnline: devices.online.contains(device), isSelected: devices.bindIsSelected(device))
                    .disabled(devices.alwaysPlayOnFavorite && device != devices.favorite)
                    .tag(device)
                }
                .onDelete(perform: delete)
                .onMove(perform: move)
            }
            .onDeleteCommand(perform: {
                print("Del")
            })
            .frame(minWidth: 200, maxWidth: 400)
        }
    }
    
    func delete(at offsets: IndexSet) {
        devices.all.remove(atOffsets: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        devices.all.move(fromOffsets: source, toOffset: destination)
    }
}

struct SpotifyDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyDevicesView(devices: SpotifyDevices(api: SpotifyEnvironmentKey.defaultValue.api))
    }
}
