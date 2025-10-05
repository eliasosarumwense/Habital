//
//  HabitWallpaperSheet.swift
//  Habital
//
//  Created by Elias Osarumwense on 17.09.25.
//

//
//  HabitWallpaperSheet.swift
//  Habital
//

import SwiftUI
import PhotosUI
import ImagePlayground

struct HabitWallpaperSheet: View {
    @Binding var selectedImage: UIImage?
    @Binding var userPrompt: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var isImagePlaygroundPresented = false
    @State private var localPrompt: String = ""
    @State private var isProcessingImage = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Current wallpaper preview
                        if let image = selectedImage {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Wallpaper")
                                    .font(.custom("Lexend-Medium", size: 12))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .kerning(0.5)
                                
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Prompt input section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Describe Your Habit Vision")
                                .font(.custom("Lexend-Medium", size: 12))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .kerning(0.5)
                            
                            VStack(spacing: 8) {
                                TextEditor(text: $localPrompt)
                                    .font(.custom("Lexend-Regular", size: 15))
                                    .frame(minHeight: 100)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                                
                                HStack {
                                    Text("\(localPrompt.count) characters")
                                        .font(.custom("Lexend-Regular", size: 11))
                                        .foregroundColor(.secondary.opacity(0.6))
                                    
                                    Spacer()
                                    
                                    Text("Describe the atmosphere, mood, or imagery")
                                        .font(.custom("Lexend-Regular", size: 11))
                                        .foregroundColor(.secondary.opacity(0.6))
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            // Image Playground button
                            Button(action: {
                                isImagePlaygroundPresented = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 18, weight: .medium))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Generate with AI")
                                            .font(.custom("Lexend-SemiBold", size: 16))
                                        Text("Create unique wallpaper using Image Playground")
                                            .font(.custom("Lexend-Regular", size: 12))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .purple.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Photo library button
                            PhotosPicker(selection: $photosPickerItem,
                                       matching: .images,
                                       photoLibrary: .shared()) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 18, weight: .medium))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Choose from Photos")
                                            .font(.custom("Lexend-SemiBold", size: 16))
                                        Text("Select an existing image from your library")
                                            .font(.custom("Lexend-Regular", size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .foregroundColor(.primary)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Remove wallpaper button (if image exists)
                            if selectedImage != nil {
                                Button(action: {
                                    withAnimation {
                                        selectedImage = nil
                                        userPrompt = ""
                                        dismiss()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("Remove Wallpaper")
                                            .font(.custom("Lexend-Medium", size: 14))
                                    }
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.red.opacity(0.1))
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Habit Wallpaper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.custom("Lexend-Regular", size: 16))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        userPrompt = localPrompt
                        dismiss()
                    }
                    .font(.custom("Lexend-SemiBold", size: 16))
                    .disabled(selectedImage == nil && localPrompt.isEmpty)
                }
            }
        }
        .imagePlaygroundSheet(
            isPresented: $isImagePlaygroundPresented,
            concepts: [
                ImagePlaygroundConcept.text(localPrompt.isEmpty ? "habit visualization" : localPrompt)
            ]
        ) { url in
            Task {
                await loadImageFromURL(url)
            }
        }
        .onChange(of: photosPickerItem) { newItem in
            Task {
                await loadImageFromPhotoPicker(newItem)
            }
        }
        .onAppear {
            localPrompt = userPrompt
        }
    }
    
    private func loadImageFromURL(_ url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    withAnimation {
                        selectedImage = image
                    }
                }
            }
        } catch {
            print("Failed to load image from URL: \(error)")
        }
    }
    
    private func loadImageFromPhotoPicker(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        await MainActor.run {
            isProcessingImage = true
        }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    withAnimation {
                        selectedImage = image
                        isProcessingImage = false
                    }
                }
            }
        } catch {
            print("Failed to load image: \(error)")
            await MainActor.run {
                isProcessingImage = false
            }
        }
    }
}
