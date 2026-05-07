# HotKey-CMD
custom made auto hot key scripts with and with out AHK


iwr -useb https://raw.githubusercontent.com/JacksonBoyle/HotKey-CMD/main/Admin/HotKey_cmd_install.ps1 -OutFile $env:TEMP\install.ps1; powershell -ExecutionPolicy Bypass -File $env:TEMP\install.ps1



Architecture

The Installer (HotKey_Installer.ps1)
The Entry Point: This is the only file a new user needs to run.

The Handshake: It uses a GUI to ask where the user wants to live (the "Install Path").

The Memory: It creates a User Data folder and saves the installation path into hotkeycmd_path.txt. This ensures the system always knows where its "home" is.

The Foundation: It downloads the latest master ZIP from GitHub, "flattens" the folder structure (removes the -main suffix), and places the files in the chosen directory.

2. The Pre-Updater (preupdate.ps1)
The Safety Net: Located in the Admin folder, this script acts as a bridge.

The Messenger: Before an update happens, it copies the latest Update Script (HK_update.ps1) and your Configuration CSVs from the system folders into the User Data "safe zone."

The Trigger: Once the files are safely moved, it launches the update process from the new location.

3. The Updater (HK_update.ps1)
The Engine: This script lives in the User Data folder.

The Logic: It reads hotkeycmd_path.txt to find the installation directory. It then fetches the newest code from GitHub and overwrites the existing system files.

The Persistence: Because it runs from the User Data folder (which is not included in the GitHub repository), it never "deletes itself" or your custom settings during an update.



## 🛠 System Architecture & Workflow

This project uses a **Persistent Deployment** strategy. It separates "System Logic" (files that get updated) from "User Data" (your personal settings).

### 📂 Folder Breakdown

| Folder | Purpose | Persistence |
| :--- | :--- | :--- |
| `Admin/` | Core scripts and `preupdate.ps1`. | **Volatile** (Overwritten on update) |
| `Library/` | Default assets and recommended configs. | **Volatile** (Overwritten on update) |
| `User Data/` | Local pathing and active user CSVs. | **Persistent** (Never touched by updates) |

---

### 🔄 The Update Cycle

1. **`HotKey_Installer.ps1`**: The user's first step. It maps the install path to `User Data/hotkeycmd_path.txt`.
2. **`Admin/preupdate.ps1`**: Acts as a bridge. It moves the latest `HK_update.ps1` and your active `.csv` files into the `User Data` "safe zone."
3. **`User Data/HK_update.ps1`**: The engine. It reads the saved path, pulls the latest master ZIP from GitHub, and refreshes the system folders without deleting your personal data.



---
