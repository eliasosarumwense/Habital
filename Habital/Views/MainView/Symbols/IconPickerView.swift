//
//  ModernIconPickerView.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.03.25.
//  Ultra-minimal, clean design with Image Playground integration
//

import SwiftUI
#if canImport(ImagePlayground)
import ImagePlayground
#endif
import PhotosUI

// MARK: - Data (Apple API only — plain systemName strings)

enum IconCategory: String, CaseIterable, Identifiable {
    case sports = "Sports"
    case health = "Health"
    case fitness = "Fitness"
    case sleep = "Sleep & Rest"
    case food = "Food & Drink"
    case medicine = "Medicine"
    case body = "Body & Senses"
    case nature = "Nature & Weather"
    case time = "Time & Calendar"
    case study = "Docs & Study"
    case people = "People"
    case audio = "Music & Audio"
    case commerce = "Commerce"
    case system = "System & Actions"
    case shapes = "Shapes & Badges"
    case misc = "Misc"

    var id: String { rawValue }
}

struct IconCatalog {
    static let healthSymbols: [String] = [
        "heart", "heart.fill", "bolt.heart.fill", "heart.text.square", "heart.text.square.fill",
        "cross", "cross.fill", "staroflife", "staroflife.fill", "staroflife.circle", "staroflife.circle.fill",
        "waveform.path.ecg", "bandage", "bandage.fill", "lungs", "lungs.fill", "figure.mind.and.body"
    ]

    static let fitnessSymbols: [String] = [
        "figure.walk", "figure.run", "figure.hiking", "figure.yoga", "figure.dance",
        "figure.cooldown", "figure.strengthtraining.functional", "dumbbell", "dumbbell.fill",
        "figure.step.training", "figure.cross.training", "figure.core.training", "figure.elliptical",
        "figure.outdoor.cycle", "figure.stairs", "figure.barre", "figure.skateboarding",
        "figure.indoor.rowing", "figure.pilates", "figure.indoor.cycle", "figure.stair.stepper"
    ]

    static let sleepSymbols: [String] = [
        "bed.double", "bed.double.fill", "moon.zzz", "moon.zzz.fill",
        "moon", "moon.fill", "sparkles", "sun.horizon", "sun.horizon.fill"
    ]

    static let foodSymbols: [String] = [
        "cup.and.saucer", "cup.and.saucer.fill", "waterbottle", "waterbottle.fill",
        "fork.knife", "fork.knife.circle", "fork.knife.circle.fill",
        "carrot", "carrot.fill", "mug", "mug.fill", "wineglass",
        "takeoutbag.and.cup.and.straw",
        "basket", "basket.fill", "cart", "cart.fill"
    ]

    static let medicineSymbols: [String] = [
        "pills", "pill", "pill.fill", "syringe", "syringe.fill",
        "medical.thermometer", "medical.thermometer.fill",
        "cross.case", "cross.case.fill", "bandage", "bandage.fill",
        "testtube.2", "stethoscope"
    ]

    static let bodySymbols: [String] = [
        "face.smiling", "face.smiling.inverse",
        "eye", "eye.fill",
        "eyeglasses", "ear", "ear.fill",
        "mouth",
        "hand.raised", "hand.raised.fill",
        "hand.wave", "hand.wave.fill",
        "hand.thumbsup", "hand.thumbsup.fill",
        "hand.thumbsdown", "hand.thumbsdown.fill",
        "hands.and.sparkles", "hands.and.sparkles.fill",
        "drop", "drop.fill", "drop.circle", "drop.circle.fill"
    ]

    static let natureSymbols: [String] = [
        "leaf", "leaf.fill", "leaf.circle", "leaf.circle.fill",
        "wind", "sun.max", "sun.max.fill", "sunrise", "sunrise.fill",
        "cloud", "cloud.sun", "cloud.sun.fill", "cloud.rain", "cloud.rain.fill",
        "thermometer.sun", "thermometer.sun.fill", "thermometer.snowflake",
        "humidity", "humidity.fill",
        "snowflake", "flame", "flame.fill"
    ]

    static let timeSymbols: [String] = [
        "timer", "timer.circle", "timer.circle.fill",
        "clock", "clock.fill", "alarm", "alarm.fill",
        "calendar", "calendar.circle", "calendar.circle.fill",
        "calendar.badge.clock", "calendar.badge.checkmark",
        "hourglass", "hourglass.bottomhalf.filled", "hourglass.tophalf.filled",
        "hourglass.circle", "hourglass.circle.fill",
        "hourglass.badge.plus",
        "clock.arrow.trianglepath"
    ]

    static let studySymbols: [String] = [
        "book", "book.fill", "books.vertical", "books.vertical.fill",
        "bookmark", "bookmark.fill",
        "document", "document.fill",
        "document.on.document", "document.on.document.fill",
        "text.document", "text.document.fill",
        "text.page.badge.magnifyingglass",
        "note.text", "pencil", "pencil.tip", "pencil.tip.crop.circle.badge.plus",
        "pencil.and.outline",
        "text.magnifyingglass", "sparkle.magnifyingglass",
        "rectangle.stack", "rectangle.stack.fill",
        "rectangle.stack.badge.person.crop.fill"
    ]

    static let peopleSymbols: [String] = [
        "person", "person.fill",
        "person.badge.plus",
        "person.fill.checkmark",
        "person.fill.questionmark",
        "person.crop.circle", "person.crop.circle.fill",
        "person.crop.circle.badge.plus", "person.crop.circle.fill.badge.plus",
        "person.crop.circle.badge.exclamationmark", "person.crop.circle.badge.exclamationmark.fill",
        "person.2", "person.2.fill", "person.3", "person.3.fill",
        "figure.mind.and.body", "brain.head.profile",
        "medal", "medal.fill",
        "lightbulb", "lightbulb.fill", "lightbulb.slash", "lightbulb.slash.fill",
        "faceid"
    ]

    static let sportsSymbols: [String] = [
        "sportscourt", "sportscourt.fill", "trophy", "trophy.fill", "rosette",
        "figure.open.water.swim", "figure.skiing.downhill", "figure.snowboarding",
        "figure.archery", "figure.tennis",
        "figure.boxing", "figure.badminton", "figure.fencing", "figure.martial.arts",
        "figure.surfing", "figure.waterpolo", "figure.track.and.field", "figure.volleyball",
        "figure.table.tennis", "figure.american.football", "figure.cricket", "figure.golf",
        "figure.bowling", "figure.baseball", "figure.indoor.soccer",
        "figure.gymnastics", "figure.climbing", "figure.rolling", "figure.wrestling"
    ]

    static let audioSymbols: [String] = [
        "microphone", "microphone.fill", "microphone.circle", "microphone.circle.fill",
        "waveform", "speaker.wave.2", "speaker.wave.2.fill",
        "hifispeaker", "hifispeaker.fill",
        "music.note", "music.note.list", "music.mic",
        "music.quarternote.3", "music.note.house", "music.note.house.fill",
        "music.note.tv", "music.note.tv.fill",
        "guitars", "guitars.fill", "sparkles.tv", "sparkles.tv.fill",
        "headphones", "headphones.circle", "headphones.circle.fill",
        "earbuds.case", "earbuds.case.fill", "radio", "radio.fill"
    ]

    static let commerceSymbols: [String] = [
        "basket", "basket.fill", "cart", "cart.fill", "bag", "bag.fill",
        "tag", "tag.fill",
        "scalemass", "scalemass.fill",
        "creditcard", "creditcard.fill",
        "banknote", "giftcard",
        "shippingbox", "shippingbox.fill"
    ]

    static let systemSymbols: [String] = [
        "bolt", "bolt.fill", "bolt.slash", "bolt.slash.fill",
        "arrow.triangle.2.circlepath", "arrow.counterclockwise",
        "repeat", "repeat.circle", "repeat.circle.fill",
        "sparkles", "sparkle",
        "gearshape", "gearshape.fill",
        "wifi", "wifi.circle", "wifi.circle.fill",
        "airplane", "lock", "lock.fill",
        "globe", "globe.americas", "globe.americas.fill",
        "globe.asia.australia", "globe.asia.australia.fill",
        "globe.central.south.asia", "globe.central.south.asia.fill",
        "globe.europe.africa", "globe.europe.africa.fill"
    ]

    static let shapesSymbols: [String] = [
        "square", "square.fill", "rectangle", "rectangle.fill",
        "circle", "circle.fill", "triangle", "triangle.fill",
        "hexagon", "hexagon.fill", "seal", "seal.fill",
        "star", "star.fill", "star.circle", "star.circle.fill",
        "target", "waveform.circle", "waveform.circle.fill",
        "bolt.circle", "bolt.circle.fill",
        "heart.circle", "heart.circle.fill",
        "bell", "bell.fill", "bell.circle", "bell.circle.fill",
        "square.grid.2x2", "square.grid.2x2.fill",
        "circle.hexagonpath", "circle.hexagonpath.fill"
    ]

    static let miscSymbols: [String] = [
        "rectangle.inset.filled",
        "sparkles.rectangle.stack", "sparkles.rectangle.stack.fill",
        "paintpalette", "paintpalette.fill",
        "paintbrush", "paintbrush.fill", "paintbrush.pointed", "paintbrush.pointed.fill",
        "wand.and.sparkles", "wand.and.sparkles.inverse",
        "globe.americas.fill"
    ]

    static let symbolsByCategory: [IconCategory: [String]] = [
        .sports: sportsSymbols,
        .health: healthSymbols,
        .fitness: fitnessSymbols,
        .sleep: sleepSymbols,
        .food: foodSymbols,
        .medicine: medicineSymbols,
        .body: bodySymbols,
        .nature: natureSymbols,
        .time: timeSymbols,
        .study: studySymbols,
        .people: peopleSymbols,
        .audio: audioSymbols,
        .commerce: commerceSymbols,
        .system: systemSymbols,
        .shapes: shapesSymbols,
        .misc: miscSymbols
    ]

    static var emojis: [String] {
        let ranges: [ClosedRange<UInt32>] = [
            0x1F600...0x1F64F, 0x1F300...0x1F5FF, 0x1F680...0x1F6FF,
            0x1F900...0x1F9FF, 0x1FA70...0x1FAFF, 0x2600...0x26FF, 0x2700...0x27BF
        ]
        var result: [String] = []
        for r in ranges {
            for code in r {
                if let scalar = UnicodeScalar(code), scalar.properties.isEmoji {
                    let s = String(scalar)
                    if !s.contains("�") && !s.contains("?") { result.append(s) }
                }
            }
        }
        return result
    }
}

// MARK: - Modern Icon Picker View

struct IconPickerView: View {
    @Binding var selectedIcon: String
    let selectedColor: Color

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var mode: Mode = .sfSymbols
    @State private var searchText: String = ""
    @State private var customEmojiText: String = ""
    
    // Image Playground states
    #if canImport(ImagePlayground)
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground
    @State private var showImagePlayground = false
    @State private var generatedImageURL: URL?
    @State private var imagePrompt: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var sourceImage: Image?
    #endif

    enum Mode: String, CaseIterable, Identifiable, Hashable {
        case sfSymbols = "Icons"
        case emoji = "Emoji"
        case aiGenerate = "AI"
        
        var id: String { rawValue }
        
        var isAvailable: Bool {
            #if canImport(ImagePlayground)
            if self == .aiGenerate {
                // This will be checked at runtime with the environment variable
                return true
            }
            #endif
            return self != .aiGenerate
        }
    }
    
    private var availableModes: [Mode] {
        Mode.allCases.filter { $0.isAvailable }
    }

    private var grid: [GridItem] {
        [GridItem(.adaptive(minimum: 44, maximum: 56), spacing: 8)]
    }

    // Emoji filtering (simple sample limiter when no search)
    private var filteredEmojis: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return Array(IconCatalog.emojis.prefix(300))
        }
        return IconCatalog.emojis.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    ModernModeToggle(
                        mode: $mode,
                        accent: selectedColor,
                        availableModes: availableModes,
                        supportsImagePlayground: supportsImagePlayground ?? false
                    )

                    if mode == .sfSymbols {
                        ModernSearchField(text: $searchText)
                    } else if mode == .emoji {
                        ModernEmojiInput(
                            text: $customEmojiText,
                            accent: selectedColor
                        ) { emoji in
                            pick(emoji)
                            dismiss()
                        }
                    } else if mode == .aiGenerate {
                        #if canImport(ImagePlayground)
                        imagePlaygroundSection
                        #endif
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(
                    Color(UIColor.systemGroupedBackground)
                        .overlay(
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(Color(UIColor.separator))
                                .opacity(0.5),
                            alignment: .bottom
                        )
                )

                // Content
                ScrollView {
                    LazyVStack(spacing: 24) {
                        if mode == .emoji {
                            ModernIconSection(
                                title: "Emoji",
                                icon: "face.smiling",
                                color: selectedColor
                            ) {
                                LazyVGrid(columns: grid, spacing: 8) {
                                    ForEach(filteredEmojis, id: \.self) { emoji in
                                        ModernEmojiBadge(
                                            emoji: emoji,
                                            selected: emoji == selectedIcon,
                                            accent: selectedColor
                                        ) {
                                            pick(emoji)
                                        }
                                    }
                                }
                            }
                        } else if mode == .sfSymbols {
                            // Symbol categories
                            ForEach(IconCategory.allCases) { category in
                                symbolsSection(for: category)
                            }
                        } else if mode == .aiGenerate {
                            #if canImport(ImagePlayground)
                            if let url = generatedImageURL {
                                ModernIconSection(
                                    title: "Generated Icon",
                                    icon: "sparkles",
                                    color: selectedColor
                                ) {
                                    VStack(spacing: 16) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 200, height: 200)
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(selectedColor.opacity(0.3), lineWidth: 1)
                                                )
                                        } placeholder: {
                                            ProgressView()
                                                .frame(width: 200, height: 200)
                                        }
                                        
                                        Button {
                                            // Save the generated image URL as the selected icon
                                            selectedIcon = url.absoluteString
                                            dismiss()
                                        } label: {
                                            Text("Use This Icon")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(selectedColor)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                }
                            }
                            #endif
                        }

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedColor)
                }
            }
            .onAppear {
                if selectedIcon.unicodeScalars.first?.properties.isEmoji == true {
                    mode = .emoji
                } else if selectedIcon.hasPrefix("http") || selectedIcon.hasPrefix("file:") {
                    mode = .aiGenerate
                }
            }
            #if canImport(ImagePlayground)
            .imagePlaygroundSheet(
                isPresented: $showImagePlayground,
                concepts: imagePrompt.isEmpty ? [] : [.text(imagePrompt)],
                sourceImage: sourceImage
            ) { url in
                generatedImageURL = url
                // Optionally save to a permanent location
                saveGeneratedImage(from: url)
            }
            #endif
        }
    }
    
    // MARK: - Image Playground Section
    
    #if canImport(ImagePlayground)
    @ViewBuilder
    private var imagePlaygroundSection: some View {
        if supportsImagePlayground == true {
            VStack(spacing: 12) {
                Text("Generate AI Icon")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    // Prompt input
                    TextField("Describe your icon...", text: $imagePrompt)
                        .font(.system(size: 16))
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
                        )
                    
                    // Optional: Add photo picker for source image
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo")
                                .font(.system(size: 14))
                            Text("Add Source Image (Optional)")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                        )
                    }
                    .onChange(of: selectedPhotoItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                sourceImage = Image(uiImage: uiImage)
                            }
                        }
                    }
                    
                    // Generate button
                    Button {
                        showImagePlayground = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Generate Icon")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        } else {
            VStack(spacing: 16) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("AI Generation Unavailable")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Image Playground requires iOS 18.1+ and a compatible device with Apple Intelligence.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 40)
        }
    }
    
    private func saveGeneratedImage(from url: URL) {
        // Save to a permanent location in your app's documents
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "icon_\(Date().timeIntervalSince1970).png"
        let permanentURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.copyItem(at: url, to: permanentURL)
            // Update the icon to use the permanent URL
            selectedIcon = permanentURL.absoluteString
        } catch {
            print("Error saving generated image: \(error)")
        }
    }
    #endif

    // MARK: - Helper Functions

    private func pick(_ value: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedIcon = value
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func filteredSymbols(for category: IconCategory) -> [String] {
        let list = IconCatalog.symbolsByCategory[category] ?? []
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return list }
        let needle = trimmed.lowercased()
        return list.filter { $0.lowercased().contains(needle) }
    }

    private func categoryIcon(for category: IconCategory) -> String {
        switch category {
        case .sports:   return "figure.run"
        case .health:   return "heart.fill"
        case .fitness:  return "dumbbell.fill"
        case .sleep:    return "moon.fill"
        case .food:     return "fork.knife"
        case .medicine: return "pills.fill"
        case .body:     return "hand.raised.fill"
        case .nature:   return "leaf.fill"
        case .time:     return "clock.fill"
        case .study:    return "book.fill"
        case .people:   return "person.fill"
        case .audio:    return "music.note"
        case .commerce: return "cart.fill"
        case .system:   return "gearshape.fill"
        case .shapes:   return "circle.fill"
        case .misc:     return "sparkles"
        }
    }

    // Build one category section (avoids `let` bindings inside ViewBuilder)
    @ViewBuilder
    private func symbolsSection(for category: IconCategory) -> some View {
        let filtered = filteredSymbols(for: category)
        if !filtered.isEmpty {
            ModernIconSection(
                title: category.rawValue,
                icon: categoryIcon(for: category),
                color: selectedColor
            ) {
                LazyVGrid(columns: grid, spacing: 8) {
                    ForEach(filtered, id: \.self) { symbol in
                        ModernSymbolBadge(
                            symbolName: symbol,
                            selected: selectedIcon == symbol,
                            accent: selectedColor
                        ) {
                            pick(symbol)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Modern UI Components

struct ModernModeToggle: View {
    @Binding var mode: IconPickerView.Mode
    let accent: Color
    let availableModes: [IconPickerView.Mode]
    let supportsImagePlayground: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(availableModes, id: \.self) { m in
                let isDisabledAI: Bool = (m == .aiGenerate) && !supportsImagePlayground
                let isSelected: Bool = (mode == m)
                let foregroundColor: Color = {
                    if isDisabledAI { return .secondary }
                    if isSelected { return accent }
                    return .secondary
                }()
                let backgroundFill: Color = isSelected ? accent.opacity(0.1) : .clear

                Button {
                    guard !(m == .aiGenerate && !supportsImagePlayground) else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        mode = m
                    }
                } label: {
                    ModeToggleLabel(mode: m, isSelected: isSelected)
                        .foregroundStyle(foregroundColor)
                        .frame(height: 36)
                        .frame(maxWidth: .infinity)
                        .background(
                            Rectangle()
                                .fill(backgroundFill)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isDisabledAI)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
}

private struct ModeToggleLabel: View {
    let mode: IconPickerView.Mode
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 4) {
            if mode == .aiGenerate {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(mode.rawValue)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
        }
    }
}

struct ModernSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search icons", text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .font(.system(size: 16))
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
}

struct ModernEmojiInput: View {
    @Binding var text: String
    let accent: Color
    let onSubmit: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("Type or paste emoji", text: $text)
                .font(.system(size: 20))
                .multilineTextAlignment(.center)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
                        )
                )

            Button {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                onSubmit(trimmed)
                text = ""
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
        }
    }
}

struct ModernIconSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content

    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.leading, 4)

            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}

struct ModernSymbolBadge: View {
    let symbolName: String
    let selected: Bool
    let accent: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(selected ? accent : .primary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? accent.opacity(0.15) : Color(UIColor.tertiarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selected ? accent.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ModernEmojiBadge: View {
    let emoji: String
    let selected: Bool
    let accent: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? accent.opacity(0.15) : Color(UIColor.tertiarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selected ? accent.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct IconPickerView_Previews: PreviewProvider {
    struct PreviewWrap: View {
        @State var selectedIcon: String = "heart.fill"
        var body: some View {
            IconPickerView(selectedIcon: $selectedIcon, selectedColor: .blue)
        }
    }

    static var previews: some View {
        Group {
            PreviewWrap()
                .previewDisplayName("Light")
            PreviewWrap()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
    }
}
