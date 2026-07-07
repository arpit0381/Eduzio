<div align="center">

<img src="https://raw.githubusercontent.com/tandpfun/skill-icons/main/icons/Flutter-Dark.svg" width="80" alt="Flutter Logo"/>

# 🎓 Eduzio

### **One Platform. Every Classroom.**

<p align="center">
  <em>A Modern Education Management Platform for Coaching Institutes, Schools & Colleges.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/Material%203-1976D2?style=for-the-badge" alt="Material 3" />
  <img src="https://img.shields.io/badge/Riverpod-5C6BC0?style=for-the-badge" alt="Riverpod" />
</p>

<p align="center">
  <strong>🚀 Fast • ☁️ Cloud Powered • 📶 Offline First • 🎨 Premium UI</strong>
</p>

</div>

---

## 📖 About Eduzio

**Eduzio** is an all-in-one Education Management Platform engineered to simplify the daily operations of educational institutes. Built with a focus on **uncompromising aesthetics** and **buttery-smooth performance**, Eduzio eliminates the need to juggle multiple apps for attendance, fees, homework, and student management.

> *"We don't just build software; we build the digital infrastructure for modern education."*

---

## 🎨 The "Iconic UI" Philosophy

Eduzio isn’t just functional; it’s an experience. We designed this platform from the ground up to feel **premium, spacious, and highly intuitive**.

* ✨ **Minimal & Elegant:** Zero visual clutter. Every pixel has a purpose.
* 📏 **Extremely Spacious:** Large typography and generous padding for frictionless navigation.
* ☁️ **Soft Shadows & Floating Cards:** Elements feel elevated and tactile.
* 🪄 **Glassmorphism:** Subtle blur effects applied exactly where they matter.
* 🎨 **Pastel Accents:** A soothing color palette that reduces eye strain for admins and teachers.

---

## 🚀 Core Modules

Eduzio is split into tailored experiences to ensure every user gets exactly what they need without the noise.

<table>
  <tr>
    <td width="50%">
      <h3>👨‍💼 Super Admin & Admin</h3>
      <ul>
        <li><b>Global Dashboard:</b> Bird's-eye view of revenue and attendance.</li>
        <li><b>Quick Actions:</b> Seamlessly jump into critical workflows.</li>
        <li><b>Batch & Subject Management:</b> Fully automated structures.</li>
        <li><b>Fee Tracking:</b> Real-time analytics and pending fee reports.</li>
      </ul>
    </td>
    <td width="50%">
      <h3>👨‍🏫 Teacher Workspace</h3>
      <ul>
        <li><b>Lightning Attendance:</b> 1-click status toggles.</li>
        <li><b>Homework & Assignments:</b> Upload and review instantly.</li>
        <li><b>Test Analytics:</b> Input marks and auto-generate ranks.</li>
        <li><b>Smart Scheduling:</b> View daily timetables effortlessly.</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>👨‍🎓 Student Portal</h3>
      <ul>
        <li><b>Instant Access:</b> Join batches instantly via <b>Batch Codes</b>.</li>
        <li><b>Academic Hub:</b> View homework, notes, and results.</li>
        <li><b>Digital ID:</b> Scan-ready QR code for physical campuses.</li>
        <li><b>Fee Status:</b> Transparent payment tracking.</li>
      </ul>
    </td>
    <td width="50%">
      <h3>👨‍👩‍👧 Parent App</h3>
      <ul>
        <li><b>Live Progress:</b> Monitor attendance and test scores.</li>
        <li><b>Push Notifications:</b> Never miss a school update.</li>
        <li><b>Direct Comms:</b> Reach out to teachers securely.</li>
      </ul>
    </td>
  </tr>
</table>

---

## ✨ Standout Features

- **📶 Offline-First Architecture:** (Coming Soon via Isar) Keep working even when the internet drops. Data syncs automatically in the background when you're back online.
- **📷 QR Code Attendance:** Scan student IDs for instant, frictionless daily check-ins.
- **📄 One-Tap PDF Reports:** Generate stunning, ready-to-print monthly reports.
- **📱 Responsive by Design:** Flawless experience across Android, iOS, Tablets, and Web browsers.

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart) |
| **Backend / BaaS** | Supabase (PostgreSQL, Auth, Edge Functions) |
| **State Management** | Riverpod 2.x |
| **Routing** | GoRouter (with ShellRoutes for Web/Desktop) |
| **UI System** | Material 3 + Custom Premium Components |

---

## 🛣 Product Roadmap

| Version | Phase | Description | Status |
|---|---|---|:---:|
| **v1.0** | MVP | Coaching Institute Core Management | ✅ |
| **v1.5** | Polish | Premium UI Overhaul & Web Optimization | 🚀 |
| **v2.0** | Scale | Online Classes, Library, Doubt Chat | 🚧 |
| **v3.0** | Enterprise | Full School/College ERP System | 📅 |

---

# Automatic APK Build

This project uses **GitHub Actions** to automate Android Release APK generation.

## How It Works

The CI/CD workflow is automated using a runner environment to execute the following steps:
1. **Checkout Repository:** Retrieves the project code.
2. **Setup JDK 17:** Installs Java Development Kit 17 (required by Gradle).
3. **Setup Flutter:** Installs the latest stable Flutter SDK.
4. **Cache Dependencies:** Restores cached Flutter Pub packages and Gradle build directories to optimize build duration.
5. **Install Dependencies:** Executes `flutter pub get`.
6. **System Verification:** Performs a `flutter doctor -v` check.
7. **Build APK:** Runs `flutter build apk --release` to compile the app.
8. **Verify Output:** Verifies the APK was built at the expected path.
9. **Upload Artifact:** Uploads the generated file as `Eduzio-Release-APK`.

## How to Trigger a Build

### 1. Automatic Trigger
Pushing or merging code changes directly to the `main` branch will automatically launch the build workflow.

### 2. Manual Trigger
To manually trigger the build workflow:
1. Navigate to the project repository on GitHub.
2. Click the **Actions** tab.
3. Select **Build Flutter APK** from the list of workflows.
4. Click the **Run workflow** dropdown button.
5. Select the target branch and click **Run workflow**.

## Where to Download the APK

Upon successful completion of the build:
1. Go to the **Actions** tab of the repository.
2. Click on the most recent run of the **Build Flutter APK** workflow.
3. Scroll down to the **Artifacts** section at the bottom.
4. Click on **Eduzio-Release-APK** to download the ZIP file containing `app-release.apk`.

## Troubleshooting Common Build Failures

* **Gradle Compilation Errors:** If Gradle fails during compiling, ensure compatibility between the Gradle version (`8.14` specified in wrapper) and JDK (Java 17). 
* **Signing Configuration:** By default, the release build type in `android/app/build.gradle.kts` uses debug signing credentials (`signingConfigs.debug`) so it compiles out-of-the-box in CI. For Play Store release, configuration of custom signing keys will be required.
* **Cache Out-of-Sync:** If dependencies fail to build due to corrupted local caches, navigate to **Actions** -> **Caches** on GitHub to clear cached data, prompting a clean reinstall on the next run.

---

<div align="center">
  <p>Built with ❤️ for modern educators.</p>
</div>
