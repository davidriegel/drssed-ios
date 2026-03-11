# Drssed – iOS App

The native iOS frontend for **Drssed**, a personal wardrobe management app that digitizes your clothing and helps you create outfits.

> This repository contains the iOS client. The backend API is maintained separately: [drssed-api](https://github.com/davidriegel/drssed-api)

---

## Features

- **Digital wardrobe** — add, organize and browse all your clothing items
- **Outfit builder** — combine items into saved outfits
- **Image processing** — automatic background removal and categorization on upload
- **Sync** — all data is stored server-side via the Drssed REST API
- **Authentication** — secure login and user account management
- **Clean UI** — focused on performance and intuitive workflows built with UIKit

---

## Tech Stack

| | Technology |
|---|---|
| Language | Swift |
| UI Framework | UIKit |
| Local Storage | Core Data |

---

## Getting Started

### Prerequisites

- Xcode 26+
- iOS 26+ deployment target
- A running instance of the [Drssed API](https://github.com/davidriegel/drssed-api)

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/davidriegel/drssed-ios.git
cd drssed-ios

# 2. Open in Xcode
open Drssed.xcodeproj
```

Configure the API base URL in the networking service to point to your local or hosted backend, then build and run on a simulator or device.

---

## Related

- **Backend API** → [davidriegel/drssed-api](https://github.com/davidriegel/drssed-api)
- **Portfolio** → [davidriegel.dev](https://davidriegel.dev)

---

## About the Project

Drssed started as a personal project to solve a real problem: losing track of what clothes you own. It grew into a full-stack application with a custom backend, a relational database, image processing features and a native iOS app.

---
