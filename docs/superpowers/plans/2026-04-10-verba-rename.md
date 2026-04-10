# Verba Rename Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the macOS app, Xcode project, module, and GitHub-facing identifiers from Verba to Verba, including the bundle identifier `com.lumiq.Verba`.

**Architecture:** Keep the existing app structure intact and perform a consistency rename across the source root, Xcode project metadata, test module, UI strings, build workflow, and documentation. The app should still build from the same codebase after the rename, but every user-facing and project-facing `Verba` reference should become `Verba`.

**Tech Stack:** SwiftUI, SwiftData, Xcode project file (`project.pbxproj`), GitHub Actions, Markdown docs.

---

### Task 1: Rename project files and source root

**Files:**
- Modify: `Verba.xcodeproj/project.pbxproj`
- Move: `Verba/` to `Verba/`
- Move: `Verba.xcodeproj/` to `Verba.xcodeproj/`

- [ ] **Step 1: Rename the source root and Xcode project directory**

```bash
mv Verba Verba
mv Verba.xcodeproj Verba.xcodeproj
```

- [ ] **Step 2: Update Xcode references to the new names**

```text
Replace Verba with Verba in the project metadata, target names, product names, file references, and test host paths.
```

- [ ] **Step 3: Verify the project file still points at the renamed folders**

```bash
rg -n "Verba|Verba" Verba.xcodeproj/project.pbxproj
```

### Task 2: Rename code, tests, UI strings, and build config

**Files:**
- Modify: `Verba/VerbaApp.swift`
- Modify: `Verba/Engine/ImportEngine.swift`
- Modify: `Verba/Views/MainCoordinatorView.swift`
- Modify: `Verba/Views/SettingsView.swift`
- Modify: `Verba/VerbaTests/*.swift`
- Modify: `Verba/Resources/Languages/*.json` if any app name strings exist
- Modify: `.github/workflows/build.yml`
- Modify: `README.md`
- Modify: `LICENSE`
- Modify: `.gitignore`

- [ ] **Step 1: Update app/module references and UI labels**

```swift
@main struct VerbaApp: App {
    // ...
}

// Example string updates:
throw NSError(domain: "Verba", code: 2, userInfo: [NSLocalizedDescriptionKey: "No valid new words found in file."])
Text(lm.t("Verba"))
@testable import Verba
```

- [ ] **Step 2: Update build settings and bundle identifiers**

```text
Set the app bundle identifier to com.lumiq.Verba and the test bundle identifier to com.lumiq.VerbaTests.
Update any test host paths to Verba.app / Verba executable names.
```

- [ ] **Step 3: Update documentation and workflow paths**

```text
Change README clone/project instructions, GitHub Actions project and scheme names, and license wording from Verba to Verba.
```

### Task 3: Verify rename completeness

**Files:**
- Modify: none

- [ ] **Step 1: Search for leftover Verba references**

```bash
rg -n --hidden --glob '!.git' --glob '!DerivedData' --glob '!*.xcuserdata' 'Verba|wordwise|WORDWISE' .
```

- [ ] **Step 2: Build the renamed project**

```bash
xcodebuild -project Verba.xcodeproj -scheme Verba -configuration Debug -sdk macosx CODE_SIGNING_ALLOWED=NO build
```

