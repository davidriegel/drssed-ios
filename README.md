# Drssed – iOS App

The native iOS frontend for **Drssed**, a personal wardrobe management app that digitizes your clothing and helps you create outfits.

> This repository contains the iOS client. The backend API is maintained separately: [drssed-api](https://github.com/davidriegel/drssed-api)

---

## Features

- **Digital wardrobe** — add, organize and browse all your clothing items
- **Outfit builder** — combine items into saved outfits
- **Image processing** — automatic background removal and categorization on upload
- **Sync** — all data is stored server-side via the Drssed REST API
- **Offline support** — local persistence via Core Data
- **Authentication** — secure login and user account management
- **Localization** — supports English and German
- **Clean UI** — focused on performance and intuitive workflows built with UIKit

---

## Getting Started

### Prerequisites

- Xcode 26+
- iOS 18+ deployment target
- A running instance of the [Drssed API](https://github.com/davidriegel/drssed-api)

### Installation

Clone the repository and open the Xcode project:

```bash
git clone https://github.com/davidriegel/drssed-ios.git
cd drssed-ios

open Drssed.xcodeproj
```

Configure the API base URL in the api configuration file `App/Configuration/APIConfig.swift` to point to your local or hosted backend, then build and run on a simulator or device.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift |
| UI Framework | UIKit |
| Sync | Custom sync layer |
| Local Storage | Core Data |


---

## Related

- **Backend API** → [davidriegel/drssed-api](https://github.com/davidriegel/drssed-api)
- **Portfolio** → [davidriegel.dev](https://davidriegel.dev)

---

## About the Project

Drssed started as a personal project to solve a real problem: losing track of what clothes you own. It grew into a full-stack application with a custom backend, a relational database, image processing features and a native iOS app.

---
