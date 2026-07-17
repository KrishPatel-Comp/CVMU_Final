# RupeeLens – Run server with tunnel & install APK

## 1. Run server with tunnel

So the APK (or emulator) can reach your local backend, run the server and expose it via tunnel:

```powershell
.\run-server-with-tunnel.ps1
```

- Opens a **server window** (FastAPI on port 8000).
- In the **current window** you get the tunnel URL: `https://rupeelens-api-krish.loca.lt`
- The app is already configured to use this URL in `rupeelens\lib\core\services\api_service.dart`.
- Press **Ctrl+C** to stop only the tunnel; close the server window when you’re done.

If the subdomain is taken, run:

```powershell
npx localtunnel --port 8000
```

Then set `baseUrl` in `rupeelens\lib\core\services\api_service.dart` to the URL shown (e.g. `https://xxx.loca.lt`).

## 2. Build and install APK

With the server + tunnel running, build and install the app:

```powershell
.\build-and-install-apk.ps1
```

- Builds a **release** APK and installs it on the device/emulator (replaces existing install).
- Ensure a device is connected or an emulator is running: `adb devices`.

Debug build (faster, larger):

```powershell
.\build-and-install-apk.ps1 -Debug
```

## Summary

| Step | Command |
|------|--------|
| Start backend + tunnel | `.\run-server-with-tunnel.ps1` |
| Build & install APK     | `.\build-and-install-apk.ps1` |

First time: in `mybackend`, create venv and install deps:  
`python -m venv venv` then `.\venv\Scripts\pip install -r requirements.txt`
