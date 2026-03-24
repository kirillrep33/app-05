import SwiftUI

struct DaySurveyScreen: View {
    private let baseWidth: CGFloat = 390
    private let baseHeight: CGFloat = 844
    @StateObject private var viewModel = DaySurveyViewModel()
    @State private var step: Int = 1
    @State private var selectedColorIndex: Int?
    @State private var showAdviceModal = false
    @State private var showPostAdviceScreen = false
    @State private var showPlayModeScreen = false
    @State private var playModeStage: PlayModeStage = .intro
    @State private var selectedTab: AppTab = .light
    @State private var selectedTired: String?
    @State private var selectedWanted: String?
    @State private var selectedCalendarDay: Int?
    @State private var entriesByDate: [String: DailyEntry] = [:]
    @State private var playStateByDate: [String: PlayDayState] = [:]
    @State private var currentAdvice = ""
    @State private var displayedMonthDate = Date()
    @State private var confettiOffset: CGFloat = 0
    @State private var showConfetti = false
    @State private var confettiOpacity: Double = 1.0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let sx = w / baseWidth
            let sy = h / baseHeight
            let topInset = geo.safeAreaInsets.top
            let bottomInset = geo.safeAreaInsets.bottom

            ZStack {
                if selectedTab == .light, showPlayModeScreen, playModeStage == .tasks {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(hex: "59168B"), location: 0.0),
                            .init(color: Color(hex: "0A1628"), location: 0.5),
                            .init(color: Color(hex: "861043"), location: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                } else {
                    Color(hex: "09182E")
                        .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    topHeader(height: 47 * sy, safeTop: topInset)

                    VStack(alignment: .leading, spacing: 0) {
                        if !topSubtitle.isEmpty {
                            Text(topSubtitle)
                                .font(.system(size: 14 * sy, weight: .regular))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 15 * sy)
                        }

                        if selectedTab == .calendar {
                            calendarContent(sx: sx, sy: sy)
                        } else if selectedTab == .stats {
                            statsContent(sx: sx, sy: sy)
                        } else if showPlayModeScreen {
                            if playModeStage == .tasks {
                                playModeTasksContent(sx: sx, sy: sy)
                            } else {
                                playModeContent(sx: sx, sy: sy)
                            }
                        } else if showPostAdviceScreen {
                            postAdviceContent(sx: sx, sy: sy)
                        } else {
                            Text(questionProgress)
                                .font(.system(size: 30 * sy / 2.1, weight: .regular))
                                .foregroundStyle(Color(hex: "A8A8A8"))
                                .padding(.top, 55 * sy)

                            Text(questionTitle)
                                .font(.system(size: 20 * sy, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.top, 14 * sy)

                            if step < 3 {
                                VStack(spacing: 16 * sy) {
                                    ForEach(currentOptions, id: \.title) { option in
                                        optionRow(emoji: option.emoji, title: option.title) {
                                            handleOptionSelection(option.title)
                                        }
                                    }
                                }
                                .padding(.top, 20 * sy)
                            } else {
                                colorGrid(sx: sx, sy: sy)
                                    .padding(.top, 20 * sy)
                            }
                        }
                    }
                    .padding(.horizontal, 24 * sx)

                    Spacer(minLength: 0)

                    if selectedTab == .light, !showPostAdviceScreen, !showPlayModeScreen, step == 3, selectedColorIndex != nil {
                        createPaletteButton(sx: sx, sy: sy)
                            .padding(.horizontal, 24 * sx)
                            .padding(.bottom, 16 * sy)
                    }

                    bottomTabBar(sx: sx, sy: sy, bottomInset: bottomInset)
                        .padding(.bottom, max(bottomInset, 12 * sy))
                }

                if showAdviceModal {
                    modalOverlay(sx: sx, sy: sy)
                }

                if selectedTab == .calendar, let day = selectedCalendarDay, let entry = selectedCalendarOverlayEntry(day: day) {
                    calendarDayDetailsOverlay(sx: sx, sy: sy, day: day, entry: entry)
                }

                if selectedTab == .light, showPlayModeScreen, playModeStage == .tasks, showConfetti {
                    confettiOverlay(screenWidth: w, screenHeight: h)
                }
            }
        }
        .onAppear {
            loadPersistedData()
            restoreFlowForToday()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
            updateRunningTimers(now: now)
        }
    }

    @ViewBuilder
    private func topHeader(height: CGFloat, safeTop: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            if !(selectedTab == .light && showPlayModeScreen && playModeStage != .intro) {
                Color(hex: "041022")
                    .ignoresSafeArea(edges: .top)
            }

            Text(headerTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .tracking(0.2)
                .textCase(.uppercase)
                .padding(.bottom, 12)
        }
        .frame(height: height )
    }

    @ViewBuilder
    private func optionRow(emoji: String, title: String, onTap: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 28))

            Text(title)
                .font(.system(size: 37 / 1.85, weight: .semibold))
                .foregroundStyle(.white)

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 20)
        .frame(height: 72)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            playButtonSound()
            onTap()
        }
    }

    @ViewBuilder
    private func bottomTabBar(sx: CGFloat, sy: CGFloat, bottomInset: CGFloat) -> some View {
        let tabBarWidth = min(294 * sx, 370)
        let tabHeight = 54 * sy

        HStack(spacing: 0) {
            tabItem(
                icon: "t-1",
                title: "Light",
                selected: selectedTab == .light,
                width: tabBarWidth / 3,
                height: tabHeight
            ) {
                switchTab(.light)
            }
            tabItem(
                icon: "t-2",
                title: "Calendar",
                selected: selectedTab == .calendar,
                width: tabBarWidth / 3,
                height: tabHeight
            ) {
                switchTab(.calendar)
            }
            tabItem(
                icon: "t-3",
                title: "Stats",
                selected: selectedTab == .stats,
                width: tabBarWidth / 3,
                height: tabHeight
            ) {
                switchTab(.stats)
            }
        }
        .frame(width: tabBarWidth, height: tabHeight)
        .padding(4)
        .background(
            Capsule(style: .continuous)
                .fill(Color(hex: "041022"))
                .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.20), lineWidth: 0.7)
        )
        .padding(.bottom, bottomInset > 0 ? 0 : 4 * sy)
    }

    @ViewBuilder
    private func tabItem(
        icon: String,
        title: String,
        selected: Bool,
        width: CGFloat,
        height: CGFloat,
        onTap: @escaping () -> Void
    ) -> some View {
        let inactiveColor = Color(hex: "A8A8A8")

        VStack(spacing: 2) {
            Image(icon)
                .resizable()
                .renderingMode(.template)
                .frame(width: 12, height: 12)
                .foregroundStyle(selected ? .white : inactiveColor)
                .opacity(selected ? 1.0 : 0.5)

            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(selected ? .white : inactiveColor)
        }
        .frame(width: width, height: height)
        .background(
            Group {
                if selected {
                    Capsule(style: .continuous)
                        .fill(Color(hex: "13568C"))
                }
            }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            playButtonSound()
            onTap()
        }
    }

    @ViewBuilder
    private func colorGrid(sx: CGFloat, sy: CGFloat) -> some View {
        let circle = min(96 * sx, 96 * sy)

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20 * sx), count: 4), spacing: 20 * sy) {
            ForEach(Array(paletteColors.enumerated()), id: \.offset) { index, item in
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color(hex: item.hex))
                        .frame(width: circle, height: circle)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(selectedColorIndex == index ? 0.95 : 0), lineWidth: 3)
                        )

                    if selectedColorIndex == index {
                        Circle()
                            .fill(Color(hex: item.hex))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 0, y: -2)
                    }
                }
                .onTapGesture {
                    playButtonSound()
                    selectedColorIndex = index
                }
            }
        }
    }

    @ViewBuilder
    private func createPaletteButton(sx: CGFloat, sy: CGFloat) -> some View {
        Button {
            playButtonSound()
            currentAdvice = generateAdvice()
            withAnimation(.easeInOut(duration: 0.2)) {
                showAdviceModal = true
            }
        } label: {
            Text("Create palette")
                .font(.system(size: 20 * sy, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46 * sy)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "E35189"), Color(hex: "EA9364")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func modalOverlay(sx: CGFloat, sy: CGFloat) -> some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    playButtonSound()
                    closeModalAndOpenNextScreen()
                }

            VStack(spacing: 0) {
                Text("Today's advice")
                    .font(.system(size: 44 * sy / 1.9, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 48 * sy)

                Text(displayedAdviceText)
                    .font(.system(size: 14 * sy, weight: .regular))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 18 * sy)
                    .padding(.horizontal, 5 * sy)

                Button {
                    playButtonSound()
                    closeModalAndOpenNextScreen()
                } label: {
                    Text("Accept")
                        .font(.system(size: 40 * sy / 1.9, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60 * sy / 1.3)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "E35189"), Color(hex: "EA9364")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 26 * sx)
                .padding(.top, 30 * sy)
                .padding(.bottom, 26 * sy)
            }
            .frame(maxWidth: .infinity)
            .background(Color(hex: "041B3B"))
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .padding(.horizontal, 24 * sx)
        }
        .transition(.opacity)
        .zIndex(5)
    }

    @ViewBuilder
    private func postAdviceContent(sx: CGFloat, sy: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .frame(height: 115 * sy)
                .overlay(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 10 * sy) {
                        Text("Today's advice")
                            .font(.system(size: 24 * sy, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(displayedAdviceText)
                            .font(.system(size: 16 * sy, weight: .regular))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20 * sx)
                }
                .padding(.top, 55 * sy)

            Spacer(minLength: 0)

            Text("Play Mode will be available after 6 p.m.")
                .font(.system(size: 16 * sy, weight: .regular))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 14 * sy)

            Button {
                playButtonSound()
                if isPlayModeAvailable {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showPlayModeScreen = true
                        playModeStage = .intro
                    }
                }
            } label: {
                HStack(spacing: 10 * sx) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22 * sy, weight: .semibold))
                    Text("Activate Play Mode")
                        .font(.system(size: 20 * sy, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46 * sy)
                .background(
                    Group {
                        if isPlayModeAvailable {
                            LinearGradient(
                                colors: [Color(hex: "AD46FF"), Color(hex: "F6339A")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color(hex: "A8A8A8")
                        }
                    }
                )
                .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!isPlayModeAvailable)
            .padding(.bottom, 24 * sy)
        }
    }

    @ViewBuilder
    private func playModeContent(sx: CGFloat, sy: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "AD46FF"), Color(hex: "F6339A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96 * sy, height: 96 * sy)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 46 * sy / 2, weight: .semibold))
                        .foregroundStyle(.white)
                }

            Text("Ready to Play?")
                .font(.system(size: 32 * sy, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 36 * sy)

            Text("Let's explode with emotions and switch to\nlife mode")
                .font(.system(size: 16 * sy, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.top, 8 * sy)

            Button {
                playButtonSound()
                withAnimation(.easeInOut(duration: 0.2)) {
                    playModeStage = .tasks
                    startConfettiOnce()
                    activatePlayModeForToday()
                    generateIdeasForToday()
                }
            } label: {
                HStack(spacing: 10 * sx) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20 * sy, weight: .semibold))
                    Text("Activate Play Mode")
                        .font(.system(size: 20 * sy, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46 * sy)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "AD46FF"), Color(hex: "F6339A")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 28 * sy)

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func playModeTasksContent(sx: CGFloat, sy: CGFloat) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 16 * sy) {
                ForEach(currentPlayIdeas) { idea in
                    playModeTaskCard(idea: idea, sx: sx, sy: sy)
                }
            }
            .padding(.top, 24 * sy)

            Button {
                playButtonSound()
                generateIdeasForToday()
            } label: {
                Text("Get New Ideas")
                    .font(.system(size: 40 * sy / 1.9, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46 * sy)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "E35189"), Color(hex: "EA9364")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 24 * sy)
            .padding(.bottom, 18 * sy)
        }
    }

    @ViewBuilder
    private func playModeTaskCard(
        idea: PlayIdea,
        sx: CGFloat,
        sy: CGFloat
    ) -> some View {
        let timerState = timerState(for: idea)
        let timerText = timerLabel(for: timerState)
        let timerActive = timerState.isRunning
        let isDone = timerState.isDone

        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .frame(height: 152 * sy)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6 * sx) {
                        Text(idea.category)
                            .font(.system(size: 13 * sy, weight: .regular))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8 * sx)
                            .padding(.vertical, 4 * sy)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule(style: .continuous))
                        Text("\(idea.minutes) min")
                            .font(.system(size: 10 * sy, weight: .regular))
                            .foregroundStyle(.white)
                    }

                    Text(idea.title)
                        .font(.system(size: 16 * sy, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.top, 24 * sy)

                    HStack(spacing: 12 * sx) {
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .fill(
                                timerActive
                                ? LinearGradient(colors: [Color(hex: "AD46FF").opacity(0.6), Color(hex: "F6339A").opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.white.opacity(0.20), Color.white.opacity(0.20)], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(height: 45 * sy)
                            .overlay {
                                Text(timerText)
                                    .font(.system(size: 14 * sy, weight: .regular))
                                    .foregroundStyle(.white)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !isDone {
                                    playButtonSound()
                                    toggleTimer(for: idea)
                                }
                            }

                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .fill(Color(hex: "4CAF50").opacity(isDone ? 1 : 0.5))
                            .frame(width: 130 * sx, height: 45 * sy)
                            .overlay {
                                Text("✓ Done!")
                                    .font(.system(size: 34 * sy / 2.1, weight: .regular))
                                    .foregroundStyle(.white)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                playButtonSound()
                                markIdeaDone(idea.id)
                            }
                    }
                    .padding(.top, 16 * sy)
                }
                .padding(.horizontal, 16 * sx)
                .padding(.top, 16 * sy)
            }
    }

    @ViewBuilder
    private func confettiOverlay(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        let confettiHeight = screenHeight
        let confettiWidth = max(screenWidth, confettiHeight * 0.47)

        ZStack {
            Image("Group 19")
                .resizable()
                .scaledToFill()
                .frame(width: confettiWidth, height: confettiHeight)
                .clipped()
                .offset(y: confettiOffset)

            Image("Group 19")
                .resizable()
                .scaledToFill()
                .frame(width: confettiWidth, height: confettiHeight)
                .clipped()
                .offset(y: confettiOffset - confettiHeight)
        }
        .frame(width: screenWidth, height: screenHeight)
        .clipped()
        .opacity(0.75 * confettiOpacity)
        .allowsHitTesting(false)
    }

    private func startConfettiOnce() {
        confettiOffset = 0
        confettiOpacity = 1
        showConfetti = true
        playBellSound()
        withAnimation(.linear(duration: 3)) {
            confettiOffset = UIScreen.main.bounds.height / 3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.linear(duration: 2)) {
                confettiOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showConfetti = false
            confettiOpacity = 1
        }
    }

    private func closeModalAndOpenNextScreen() {
        persistSurveyEntryForCalendar()
        withAnimation(.easeInOut(duration: 0.2)) {
            showAdviceModal = false
            showPostAdviceScreen = true
        }
    }

    private func handleOptionSelection(_ title: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if step == 1 {
                selectedTired = title
            } else if step == 2 {
                selectedWanted = title
            }
            step += 1
        }
    }

    private func persistSurveyEntryForCalendar() {
        guard
            let tired = selectedTired,
            let wanted = selectedWanted,
            let color = selectedSurveyColor
        else { return }

        let key = dateKey(for: Date())
        entriesByDate[key] = DailyEntry(
            tired: tired,
            wanted: wanted,
            colorName: color.name,
            colorHex: color.hex,
            colorAssociation: color.meaning,
            advice: displayedAdviceText,
            playModeActivated: entriesByDate[key]?.playModeActivated ?? false,
            completedIdeaIDs: entriesByDate[key]?.completedIdeaIDs ?? []
        )
        saveEntries()
    }

    private func selectedCalendarOverlayEntry(day: Int) -> DayEntry? {
        guard let date = dateForDay(day) else { return nil }
        let key = dateKey(for: date)
        guard let entry = entriesByDate[key] else { return nil }
        return DayEntry(
            color: PaletteColor(name: entry.colorName, hex: entry.colorHex, meaning: entry.colorAssociation),
            tired: entry.tired,
            wanted: entry.wanted,
            advice: entry.advice
        )
    }

    private func dayTextColor(for entry: DayEntry?) -> Color {
        guard let entry else { return .white }
        if entry.color.hex == "FFEB3B" || entry.color.hex == "FFFFFF" {
            return Color(hex: "09182E")
        }
        return .white
    }

    @ViewBuilder
    private func calendarDayDetailsOverlay(sx: CGFloat, sy: CGFloat, day: Int, entry: DayEntry) -> some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    playButtonSound()
                    selectedCalendarDay = nil
                }

            VStack(alignment: .leading, spacing: 0) {


                Text(fullDateTitle(for: day))
                    .font(.system(size: 24 * sy, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 26 * sy)
                    .padding(.horizontal, 24 * sx)

                HStack(spacing: 8 * sx) {
                    Circle()
                        .fill(Color(hex: entry.color.hex))
                        .frame(width: 50 * sy, height: 50 * sy)
                    VStack(alignment: .leading, spacing: 4 * sy) {
                        Text("Color")
                            .font(.system(size: 14 * sy, weight: .regular))
                            .foregroundStyle(Color(hex: "A8A8A8"))
                        Text(entry.color.name)
                            .font(.system(size: 34 * sy / 2.1, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 20 * sy)
                .padding(.horizontal, 24 * sx)

                HStack(spacing: 16 * sx) {
                    calendarInfoCard(title: "What's tired", value: entry.tired, sx: sx, sy: sy)
                    calendarInfoCard(title: "What wanted", value: entry.wanted, sx: sx, sy: sy)
                }
                .padding(.top, 18 * sy)
                .padding(.horizontal, 24 * sx)

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 99 * sy)
                    .overlay(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 4 * sy) {
                            Text("Advice given")
                                .font(.system(size: 14 * sy, weight: .regular))
                                .foregroundStyle(Color(hex: "A8A8A8"))
                            Text(entry.advice)
                                .font(.system(size: 16 * sy, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 16 * sx)
                    }
                    .padding(.top, 18 * sy)
                    .padding(.horizontal, 24 * sx)

                Button {
                    playButtonSound()
                    selectedCalendarDay = nil
                } label: {
                    Text("Close")
                        .font(.system(size: 20 * sy, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46 * sy)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "E35189"), Color(hex: "EA9364")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 24 * sy)
                .padding(.horizontal, 21 * sx)
                .padding(.bottom, 20 * sy)
            }
            .frame(maxWidth: .infinity)
            .background(Color(hex: "09182E"))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .zIndex(10)
    }

    @ViewBuilder
    private func calendarInfoCard(title: String, value: String, sx: CGFloat, sy: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .frame(height: 80 * sy)
            .overlay(alignment: .leading) {
                VStack(alignment: .leading, spacing: 6 * sy) {
                    Text(title)
                        .font(.system(size: 14 * sy, weight: .regular))
                        .foregroundStyle(Color(hex: "A8A8A8"))
                    Text(value)
                        .font(.system(size: 16 * sy, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16 * sx)
            }
    }

    @ViewBuilder
    private func calendarContent(sx: CGFloat, sy: CGFloat) -> some View {
        let days = daysInDisplayedMonth
        VStack(spacing: 0) {
            HStack {
                calendarArrowButton(icon: "chevron.left", sx: sx, sy: sy)
                    .onTapGesture {
                        playButtonSound()
                        changeMonth(by: -1)
                    }
                Spacer(minLength: 0)
                Text(monthTitle)
                    .font(.system(size: 41 * sy / 1.65, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                calendarArrowButton(icon: "chevron.right", sx: sx, sy: sy)
                    .onTapGesture {
                        playButtonSound()
                        changeMonth(by: 1)
                    }
            }
            .padding(.top, 38 * sy)

            VStack(spacing: 12 * sy) {
                HStack {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12 * sy, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8 * sx), count: 7), spacing: 8 * sy) {
                    ForEach(1...days, id: \.self) { day in
                        let entry = selectedCalendarOverlayEntry(day: day)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(entry.map { Color(hex: $0.color.hex) } ?? Color.white.opacity(0.05))
                            .frame(height: 44 * sy)
                            .overlay {
                                Text("\(day)")
                                    .font(.system(size: 29 * sy / 2.1, weight: .medium))
                                    .foregroundStyle(dayTextColor(for: entry))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard entry != nil else { return }
                                playButtonSound()
                                selectedCalendarDay = day
                            }
                    }
                }
            }
            .padding(.horizontal, 16 * sx)
            .padding(.top, 16 * sy)
            .padding(.bottom, 16 * sy)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.top, 22 * sy)
        }
    }

    @ViewBuilder
    private func calendarArrowButton(icon: String, sx: CGFloat, sy: CGFloat) -> some View {
        Circle()
            .fill(Color.white.opacity(0.05))
            .frame(width: 40 * sx, height: 40 * sy)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: 18 * sy, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }

    @ViewBuilder
    private func statsContent(sx: CGFloat, sy: CGFloat) -> some View {
        if totalDays > 0 {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    statsPaletteOfMonthCard(sx: sx, sy: sy)
                        .padding(.top, 24 * sy)

                    HStack(spacing: 16 * sx) {
                        statsCard(title: "Total Days", value: "\(totalDays)", subtitle: nil, gradient: nil, iconName: "Icon-2", sx: sx, sy: sy, height: 90 * sy)
                        statsCard(
                            title: "Play Mode",
                            value: "\(playModeDays)",
                            subtitle: nil,
                            gradient: [Color(hex: "AD46FF").opacity(0.5), Color(hex: "F6339A").opacity(0.5)],
                            iconName: "Icon-3",
                            sx: sx,
                            sy: sy,
                            height: 90 * sy
                        )
                    }
                    .padding(.top, 16 * sy)

                    HStack(spacing: 16 * sx) {
                        statsCard(title: "Current Streak", value: "\(currentStreak)", subtitle: "days in a row", gradient: nil, iconName: "Icon-4", sx: sx, sy: sy, height: 110 * sy)
                        statsCard(title: "Longest Streak", value: "\(longestStreak)", subtitle: "days in a row", gradient: nil, iconName: "Icon-4", sx: sx, sy: sy, height: 110 * sy)
                    }
                    .padding(.top, 16 * sy)

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 90 * sy)
                        .overlay {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Most Frequent \"What's Tired\"")
                                    .font(.system(size: 32 * sy / 2.3, weight: .regular))
                                    .foregroundStyle(Color(hex: "A8A8A8"))
                                Spacer(minLength: 0)
                                HStack {
                                    Text(mostFrequentTired)
                                        .font(.system(size: 24 * sy, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(mostFrequentTiredCount) times")
                                        .font(.system(size: 13 * sy, weight: .regular))
                                        .foregroundStyle(Color(hex: "A8A8A8"))
                                }
                            }
                            .padding(.horizontal, 16 * sx)
                            .padding(.vertical, 20 * sy)
                        }
                        .padding(.top, 16 * sy)

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 142 * sy)
                        .overlay(alignment: .leading) {
                            VStack(alignment: .leading, spacing: 10 * sy) {
                                Text("Most Frequent Color")
                                    .font(.system(size: 14 * sy, weight: .regular))
                                    .foregroundStyle(Color(hex: "A8A8A8"))
                                HStack(spacing: 8 * sx) {
                                    Circle()
                                        .fill(Color(hex: mostFrequentColor.hex))
                                        .frame(width: 50 * sy, height: 50 * sy)
                                    VStack(alignment: .leading, spacing: 4 * sy) {
                                        Text(mostFrequentColor.name)
                                            .font(.system(size: 16 * sy, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("\(mostFrequentColorCount) times")
                                            .font(.system(size: 14 * sy, weight: .regular))
                                            .foregroundStyle(Color(hex: "A8A8A8"))
                                    }
                                }
                                Text(mostFrequentColor.meaning)
                                    .font(.system(size: 14 * sy, weight: .regular))
                                    .foregroundStyle(Color(hex: "A8A8A8"))
                            }
                            .padding(.horizontal, 16 * sx)
                            .padding(.vertical, 20 * sy)
                        }
                        .padding(.top, 20 * sy)
                        .padding(.bottom, 28 * sy)
                }
            }
        } else {
            VStack(spacing: 0) {
            HStack(spacing: 16 * sx) {
                statsCard(title: "Total Days", value: "0", subtitle: nil, gradient: nil, iconName: "Icon-2", sx: sx, sy: sy, height: 90 * sy)
                statsCard(
                    title: "Play Mode",
                    value: "0",
                    subtitle: nil,
                    gradient: [Color(hex: "AD46FF").opacity(0.5), Color(hex: "F6339A").opacity(0.5)],
                    iconName: "Icon-3",
                    sx: sx,
                    sy: sy,
                    height: 90 * sy
                )
            }
            .padding(.top, 24 * sy)

            HStack(spacing: 16 * sx) {
                statsCard(title: "Current Streak", value: "0", subtitle: "days in a row", gradient: nil, iconName: "Icon-4", sx: sx, sy: sy, height: 110 * sy)
                statsCard(title: "Longest Streak", value: "0", subtitle: "days in a row", gradient: nil, iconName: "Icon-4", sx: sx, sy: sy, height: 110 * sy)
            }
            .padding(.top, 16 * sy)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .frame(height: 84 * sy)
                .overlay {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Most Frequent \"What's Tired\"")
                            .font(.system(size: 32 * sy / 2.3, weight: .regular))
                            .foregroundStyle(Color(hex: "A8A8A8"))
                        Spacer(minLength: 0)
                        HStack {
                            Spacer()
                            Text("0 times")
                                .font(.system(size: 13 * sy, weight: .regular))
                                .foregroundStyle(Color(hex: "A8A8A8"))
                        }
                    }
                    .padding(.horizontal, 16 * sx)
                    .padding(.vertical, 20 * sy)
                }
                .padding(.top, 16 * sy)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .frame(height: 107 * sy)
                .overlay {
                    VStack(spacing: 10 * sy) {
                        Text("No data yet")
                            .font(.system(size: 16 * sy, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Complete your daily palette to see\nstatistics")
                            .font(.system(size: 16 * sy, weight: .regular))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color(hex: "A8A8A8"))
                    }
                    .padding(.horizontal, 20 * sx)
                }
                .padding(.top, 22 * sy)
            }
        }
    }

    @ViewBuilder
    private func statsCard(
        title: String,
        value: String,
        subtitle: String?,
        gradient: [Color]?,
        iconName: String?,
        sx: CGFloat,
        sy: CGFloat,
        height: CGFloat
    ) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .overlay {
                if let gradient, gradient.count == 2 {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
                }
            }
            .frame(height: height)
            .overlay(alignment: .leading) {
                VStack(alignment: .leading, spacing: 4 * sy) {
                    HStack(spacing: 4 * sx) {
                        if let iconName {
                            Image(iconName)
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 16 * sy, height: 16 * sy)
                                .foregroundStyle(Color(hex: "A8A8A8"))
                        }
                        Text(title)
                            .font(.system(size: 14 * sy, weight: .regular))
                            .foregroundStyle(Color(hex: "A8A8A8"))
                    }
                    Text(value)
                        .font(.system(size: 24 * sy, weight: .semibold))
                        .foregroundStyle(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13 * sy, weight: .regular))
                            .foregroundStyle(Color(hex: "A8A8A8"))
                            .padding(.top, 2 * sy)
                    }
                }
                .padding(.horizontal, 16 * sx)
                .padding(.top, -10 * sy)
            }
    }

    @ViewBuilder
    private func statsPaletteOfMonthCard(sx: CGFloat, sy: CGFloat) -> some View {
        let items = paletteColors.map { color in
            (color, colorCounts[color.hex] ?? 0)
        }
        let donutColors = donutSegments

        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6 * sx) {
                        Image("Icon-5")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 17 * sy, height: 17 * sy)
                            .foregroundStyle(.white)
                        Text("Color Palette of the Month")
                            .font(.system(size: 16 * sy, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 20 * sy)
                    .padding(.horizontal, 20 * sx)

                    donutChart(colors: donutColors, sx: sx, sy: sy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12 * sy)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16 * sx), count: 2), spacing: 12 * sy) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.20))
                                .frame(height: 32 * sy)
                                .overlay {
                                    HStack(spacing: 6 * sx) {
                                        Circle()
                                            .fill(Color(hex: item.0.hex))
                                            .frame(width: 16 * sy, height: 16 * sy)
                                        Text(item.0.name)
                                            .font(.system(size: 10 * sy, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Spacer(minLength: 0)
                                        Text("\(item.1)")
                                            .font(.system(size: 10 * sy, weight: .regular))
                                            .foregroundStyle(.white)
                                    }
                                    .padding(.horizontal, 8 * sx)
                                }
                        }
                    }
                    .padding(.horizontal, 20 * sx)
                    .padding(.top, 18 * sy)
                }
            }
            .frame(height: 531 * sy)
    }

    @ViewBuilder
    private func donutChart(colors: [String], sx: CGFloat, sy: CGFloat) -> some View {
        let count = CGFloat(max(colors.count, 1))
        let size = 180 * sy

        ZStack {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, hex in
                let start = CGFloat(index) / count
                let end = CGFloat(index + 1) / count

                RingSegmentShape(start: start, end: end, thickness: 0.33)
                    .fill(Color(hex: hex))
                    .overlay(
                        RingSegmentShape(start: start, end: end, thickness: 0.33)
                            .stroke(Color(hex: "13568C"), lineWidth: 2)
                    )
            }

            Circle()
                .fill(Color(hex: "162A48"))
                .frame(width: 106 * sy, height: 106 * sy)

        }
        .frame(width: size, height: size)
    }

    private func switchTab(_ tab: AppTab) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = tab
            showAdviceModal = false
            selectedCalendarDay = nil
            if tab == .light {
                restoreFlowForToday()
            } else {
                showPlayModeScreen = false
                playModeStage = .intro
            }
        }
    }

    private var headerTitle: String {
        if selectedTab == .light, showPlayModeScreen {
            return "PLAY MODE"
        }
        switch selectedTab {
        case .calendar: return "EMOTION CALENDAR"
        case .stats: return "STATS"
        case .light: return "HOW WAS YOUR DAY?"
        }
    }

    private var topSubtitle: String {
        if selectedTab == .light, showPlayModeScreen {
            return playModeStage == .tasks ? "Let's do something fun and spontaneous" : ""
        }
        switch selectedTab {
        case .calendar: return "Track your emotional journey"
        case .stats: return "Your emotional journey insights"
        case .light: return "Your day doesn't end in gray. Color your evening"
        }
    }

    private var isPlayModeAvailable: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 18 || hour < 8
    }

    private var displayedAdviceText: String {
        currentAdvice.isEmpty ? generateAdvice() : currentAdvice
    }

    private var selectedSurveyColor: PaletteColor? {
        guard let selectedColorIndex else { return nil }
        guard paletteColors.indices.contains(selectedColorIndex) else { return nil }
        return paletteColors[selectedColorIndex]
    }

    private var paletteColors: [PaletteColor] {
        [
            PaletteColor(name: "Green", hex: "4CAF50", meaning: "Nature, calm, balance"),
            PaletteColor(name: "Blue", hex: "2196F3", meaning: "Silence, depth, cold"),
            PaletteColor(name: "Purple", hex: "9C27B0", meaning: "Creativity, magic, intuition"),
            PaletteColor(name: "Orange", hex: "FF9800", meaning: "Communication, warmth, energy"),
            PaletteColor(name: "Gray", hex: "9E9E9E", meaning: "Work, routine, neutrality"),
            PaletteColor(name: "Red", hex: "F44336", meaning: "Passion, anger, drive"),
            PaletteColor(name: "Yellow", hex: "FFEB3B", meaning: "Joy, light, optimism"),
            PaletteColor(name: "Pink", hex: "E91E63", meaning: "Care, tenderness, love"),
            PaletteColor(name: "Black", hex: "212121", meaning: "Deep rest, silence, sleep"),
            PaletteColor(name: "White", hex: "FFFFFF", meaning: "Clarity, clean start, order"),
            PaletteColor(name: "Brown", hex: "795548", meaning: "Grounding, stability, home"),
            PaletteColor(name: "Turquoise", hex: "00BCD4", meaning: "Renewal, freshness, change")
        ]
    }

    private var playIdeasPool: [PlayIdea] {
        viewModel.playIdeasPool
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: displayedMonthDate)
    }

    private var daysInDisplayedMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: displayedMonthDate)?.count ?? 30
    }

    private var totalDays: Int {
        entriesByDate.count
    }

    private var playModeDays: Int {
        entriesByDate.values.filter { $0.playModeActivated }.count
    }

    private var colorCounts: [String: Int] {
        entriesByDate.values.reduce(into: [String: Int]()) { result, entry in
            result[entry.colorHex, default: 0] += 1
        }
    }

    private var donutSegments: [String] {
        let expanded = paletteColors.flatMap { color in
            Array(repeating: color.hex, count: max(0, colorCounts[color.hex] ?? 0))
        }
        return expanded.isEmpty ? paletteColors.map(\.hex) : expanded
    }

    private var mostFrequentTired: String {
        let counts = entriesByDate.values.reduce(into: [String: Int]()) { $0[$1.tired, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key ?? "Body"
    }

    private var mostFrequentTiredCount: Int {
        entriesByDate.values.filter { $0.tired == mostFrequentTired }.count
    }

    private var mostFrequentColor: PaletteColor {
        let bestHex = colorCounts.max(by: { $0.value < $1.value })?.key ?? "2196F3"
        return paletteColors.first(where: { $0.hex == bestHex }) ?? paletteColors[1]
    }

    private var mostFrequentColorCount: Int {
        colorCounts[mostFrequentColor.hex] ?? 0
    }

    private var sortedEntryDates: [Date] {
        entriesByDate.keys.compactMap(dateFromKey(_:)).sorted()
    }

    private var longestStreak: Int {
        guard !sortedEntryDates.isEmpty else { return 0 }
        var best = 1
        var current = 1
        for index in 1..<sortedEntryDates.count {
            let prev = sortedEntryDates[index - 1]
            let date = sortedEntryDates[index]
            if Calendar.current.dateComponents([.day], from: prev, to: date).day == 1 {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }

    private var currentStreak: Int {
        guard !sortedEntryDates.isEmpty else { return 0 }
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())
        while entriesByDate[dateKey(for: date)] != nil {
            streak += 1
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return streak
    }

    private var questionProgress: String {
        "Question \(step) of 3"
    }

    private var questionTitle: String {
        switch step {
        case 1: return "What's tired?"
        case 2: return "What do you want?"
        default: return "What color is today?"
        }
    }

    private var currentOptions: [(emoji: String, title: String)] {
        switch step {
        case 1:
            return [("💪", "Body"), ("🧠", "Mind"), ("✨", "Soul")]
        case 2:
            return [("🤫", "Silence"), ("🏃", "Movement"), ("💬", "Communication")]
        default:
            return []
        }
    }

    private func generateAdvice() -> String {
        viewModel.generateAdvice(tired: selectedTired, wanted: selectedWanted, colorName: selectedSurveyColor?.name)
    }

    private func dateKey(for date: Date) -> String {
        viewModel.dateKey(for: date)
    }

    private func dateFromKey(_ key: String) -> Date? {
        viewModel.dateFromKey(key)
    }

    private func dateForDay(_ day: Int) -> Date? {
        let comps = Calendar.current.dateComponents([.year, .month], from: displayedMonthDate)
        var dayComps = DateComponents()
        dayComps.year = comps.year
        dayComps.month = comps.month
        dayComps.day = day
        return Calendar.current.date(from: dayComps)
    }

    private func fullDateTitle(for day: Int) -> String {
        guard let date = dateForDay(day) else { return "Date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private func changeMonth(by value: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: value, to: displayedMonthDate) else { return }
        displayedMonthDate = next
    }

    private func loadPersistedData() {
        entriesByDate = viewModel.loadEntries()
        playStateByDate = viewModel.loadPlayStates()
        displayedMonthDate = Date()
    }

    private func restoreFlowForToday() {
        selectedTab = .light
        selectedCalendarDay = nil
        showAdviceModal = false
        showConfetti = false
        confettiOpacity = 1
        confettiOffset = 0

        let key = todayKey
        guard let entry = entriesByDate[key] else {
            step = 1
            selectedTired = nil
            selectedWanted = nil
            selectedColorIndex = nil
            currentAdvice = ""
            showPostAdviceScreen = false
            showPlayModeScreen = false
            playModeStage = .intro
            return
        }

        selectedTired = entry.tired
        selectedWanted = entry.wanted
        selectedColorIndex = paletteColors.firstIndex(where: { $0.hex == entry.colorHex })
        currentAdvice = entry.advice
        step = 3

        if entry.playModeActivated {
            showPostAdviceScreen = false
            showPlayModeScreen = true
            let hasIdeas = !(playStateByDate[key]?.currentIdeaIDs.isEmpty ?? true)
            playModeStage = hasIdeas ? .tasks : .intro
        } else {
            showPostAdviceScreen = true
            showPlayModeScreen = false
            playModeStage = .intro
        }
    }

    private func saveEntries() {
        viewModel.saveEntries(entriesByDate)
    }

    private func savePlayState() {
        viewModel.savePlayStates(playStateByDate)
    }

    private var todayKey: String {
        dateKey(for: Date())
    }

    private var currentPlayIdeas: [PlayIdea] {
        let ids = playStateByDate[todayKey]?.currentIdeaIDs ?? []
        return ids.compactMap { id in playIdeasPool.first(where: { $0.id == id }) }
    }

    private func activatePlayModeForToday() {
        let key = todayKey
        if var existing = entriesByDate[key] {
            existing.playModeActivated = true
            entriesByDate[key] = existing
            saveEntries()
        }
    }

    private func generateIdeasForToday() {
        let key = todayKey
        var state = playStateByDate[key] ?? PlayDayState(shownIdeaIDs: [], currentIdeaIDs: [], timers: [:])
        let allIDs = playIdeasPool.map(\.id)
        var available = allIDs.filter { !state.shownIdeaIDs.contains($0) }
        if available.count < 3 {
            state.shownIdeaIDs = []
            available = allIDs
        }
        let picks = Array(available.shuffled().prefix(3))
        state.currentIdeaIDs = picks
        state.shownIdeaIDs.append(contentsOf: picks)
        for id in picks {
            if let idea = playIdeasPool.first(where: { $0.id == id }) {
                state.timers[id] = IdeaTimerState(remainingSeconds: idea.minutes * 60, isRunning: false, startedAt: nil, isDone: false)
            }
        }
        playStateByDate[key] = state
        savePlayState()
    }

    private func timerState(for idea: PlayIdea) -> IdeaTimerState {
        if let state = playStateByDate[todayKey]?.timers[idea.id] {
            return state
        }
        return IdeaTimerState(remainingSeconds: idea.minutes * 60, isRunning: false, startedAt: nil, isDone: false)
    }

    private func timerLabel(for state: IdeaTimerState) -> String {
        if state.remainingSeconds <= 0 {
            return "⏱ 00:00"
        }
        if !state.isRunning && state.startedAt == nil {
            return "⏱ Start Timer"
        }
        let minutes = state.remainingSeconds / 60
        let seconds = state.remainingSeconds % 60
        return String(format: "⏱ %02d:%02d", minutes, seconds)
    }

    private func toggleTimer(for idea: PlayIdea) {
        var state = playStateByDate[todayKey] ?? PlayDayState(shownIdeaIDs: [], currentIdeaIDs: [], timers: [:])
        var timer = state.timers[idea.id] ?? IdeaTimerState(remainingSeconds: idea.minutes * 60, isRunning: false, startedAt: nil, isDone: false)
        if timer.isDone { return }
        if timer.isRunning {
            if let startedAt = timer.startedAt {
                let elapsed = max(0, Int(Date().timeIntervalSince1970 - startedAt))
                timer.remainingSeconds = max(0, timer.remainingSeconds - elapsed)
            }
            timer.isRunning = false
            timer.startedAt = nil
        } else {
            timer.isRunning = true
            timer.startedAt = Date().timeIntervalSince1970
        }
        state.timers[idea.id] = timer
        playStateByDate[todayKey] = state
        savePlayState()
    }

    private func updateRunningTimers(now: Date) {
        guard var state = playStateByDate[todayKey] else { return }
        var changed = false
        for id in state.currentIdeaIDs {
            guard var timer = state.timers[id], timer.isRunning, let startedAt = timer.startedAt else { continue }
            let elapsed = max(0, Int(now.timeIntervalSince1970 - startedAt))
            if elapsed > 0 {
                timer.remainingSeconds = max(0, timer.remainingSeconds - elapsed)
                timer.startedAt = now.timeIntervalSince1970
                if timer.remainingSeconds == 0 {
                    timer.isRunning = false
                    timer.startedAt = nil
                    timer.isDone = true
                    markCompletedIdeaInEntry(id)
                }
                state.timers[id] = timer
                changed = true
            }
        }
        if changed {
            playStateByDate[todayKey] = state
            savePlayState()
        }
    }

    private func markIdeaDone(_ ideaID: Int) {
        var state = playStateByDate[todayKey] ?? PlayDayState(shownIdeaIDs: [], currentIdeaIDs: [], timers: [:])
        var timer = state.timers[ideaID] ?? IdeaTimerState(remainingSeconds: 0, isRunning: false, startedAt: nil, isDone: true)
        timer.isDone = true
        timer.isRunning = false
        timer.startedAt = nil
        state.timers[ideaID] = timer
        playStateByDate[todayKey] = state
        savePlayState()
        markCompletedIdeaInEntry(ideaID)
    }

    private func markCompletedIdeaInEntry(_ ideaID: Int) {
        if var entry = entriesByDate[todayKey], !entry.completedIdeaIDs.contains(ideaID) {
            entry.completedIdeaIDs.append(ideaID)
            entriesByDate[todayKey] = entry
            saveEntries()
        }
    }

    private func playButtonSound() {
        AudioPlayerService.shared.playButtonSound()
    }

    private func playBellSound() {
        AudioPlayerService.shared.playBellSound()
    }
}

#Preview {
    DaySurveyScreen()
}
