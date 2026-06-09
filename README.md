# Magrana ⌚️

**Stay close to the people who matter — right from your wrist.**

Magrana is a watchOS-first app for nurturing the relationships in your life. Set your mood, send lightweight nudges, suggest songs, build streaks, and unlock achievements with the people you care about. Designed for the small screen first, every interaction is glanceable, tactile, and quick.

---

## ✨ Features

- **People Spaces** — Each person gets their own beautifully animated space with a custom color, emoji, and relationship type (partner, best friend, parent, coworker, and 12 more).
- **Mood Sharing** — Spin the Digital Crown to pick from 12 moods. The whole space re-tints to match how you feel.
- **Nudges** — Send a lightweight signal — "Thinking of You," "Miss You," "Great Work" — with relationship-aware suggestions.
- **Activity Rings** — Three Apple-Watch-style rings track your daily streak, weekly nudges, and daily challenges, complete with particle bursts when you close them.
- **Challenges** — Daily, weekly, and monthly goals that auto-reset, plus your own custom challenges.
- **Achievements** — 20+ unlockable trophies across streaks, nudges, moods, music, and time — including hidden secret ones to discover.
- **Song Suggestions** — Share a track with someone in your space.
- **Streaks** — Keep the connection alive day after day.

## 🎨 Design

- **watchOS-first.** Every layout is built for the small screen and scales fluidly from the 40mm SE to the 49mm Ultra.
- **Liquid Glass** styling throughout for a modern, depth-rich feel.
- **Haptics & motion.** Spring animations, floating particles, and success haptics make every interaction feel alive.

## 🏗️ Architecture

Magrana is built with **SwiftUI** and **SwiftData**, organized by feature:

```
Magrana Watch App/
├── MagranaApp.swift        # @main — sets up the SwiftData container
├── Models/                # @Model data types + supporting enums
│   ├── Contact.swift      #   a person + relationship, streak, stats, customization
│   ├── Mood.swift         #   MoodType + MoodEntry
│   ├── Nudge.swift        #   NudgeType + NudgeEntry
│   ├── Challenge.swift    #   built-in daily/weekly/monthly goals
│   ├── CustomChallenge.swift
│   ├── Achievement.swift  #   unlockable trophies
│   └── SongSuggestion.swift
├── Services/              # stateless business logic
│   ├── StreakService.swift       # consecutive-day streak tracking
│   ├── ChallengeService.swift    # challenge progress + period resets
│   └── AchievementService.swift  # achievement unlock checks
└── Views/                 # UI, grouped by feature
    ├── Home/              #   MainTabView (root, swipeable spaces)
    ├── Space/             #   PersonSpaceView, Goals, Challenges, Achievements, Settings
    ├── MoodPicker/        #   MoodSelectionView
    ├── Nudge/             #   SendNudgeView
    ├── Music/             #   SuggestSongView
    └── Onboarding/        #   OnboardingView
```

### Data & persistence

All data is stored locally with **SwiftData** (`@Model` classes). There are no manual migrations yet — instead, `MagranaApp.swift` keeps a `schemaVersion` string. Bumping it wipes the local store on next launch, so model changes during development never cause crashes from stale data.

### Logic

Business logic lives in stateless service enums, keeping views focused on presentation:

- **`StreakService`** — increments a streak on consecutive-day interactions, resets when a day is skipped.
- **`ChallengeService`** — advances challenge progress on each mood/nudge and resets challenges when their period rolls over.
- **`AchievementService`** — evaluates all achievement conditions after an interaction and surfaces any newly unlocked trophy.

## 🚀 Getting started

### Requirements

- Xcode 16 or later
- watchOS 26 SDK (uses Liquid Glass APIs)
- An Apple Watch Series 4+ or the watchOS Simulator

### Build & run

1. Clone the repo:
   ```bash
   git clone <your-repo-url>
   cd Magrana
   ```
2. Open the project:
   ```bash
   open Magrana.xcodeproj
   ```
3. Select the **Magrana Watch App** scheme and a watch simulator (or your device).
4. Press **⌘R** to build and run.

## 🗺️ Roadmap

- [ ] **Cross-user sync** — real-time mood and nudge delivery between people (the app is currently local-only).
- [ ] **iOS & macOS widgets** — read-only, glanceable dashboards showing live stats.
- [ ] Richer relationship-specific experiences.

## 📄 License

_Add your license here._

---

Built with ❤️ for staying connected.
