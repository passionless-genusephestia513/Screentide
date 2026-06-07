# Screentide 🌊

Screentide is a customizable, responsive screen-time tracking widget for the **KDE Plasma 6** desktop. It connects to your local, open-source **[ActivityWatch](https://activitywatch.net/)** server to show today's usage total, hourly activity charts, and top apps at a glance.

<p align="center">
  <table border="0">
    <tr>
      <td align="center" width="50%">
        <img src="screenshots/landscape_purple_minimal.jpeg" alt="Landscape Purple Minimal" width="100%"/>
        <br>
      </td>
      <td align="center" width="50%">
        <img src="screenshots/landscape_dark_red.jpeg" alt="Landscape Dark Red" width="100%"/>
        <br>
      </td>
    </tr>
    <tr>
      <td align="center" width="50%">
        <img src="screenshots/portrait_sunset_orange.jpeg" alt="Portrait Sunset Orange" width="100%"/>
        <br>
      </td>
      <td align="center" width="50%">
        <img src="screenshots/portrait_anime_green.jpeg" alt="Portrait Accent Styling" width="100%"/>
        <br>
      </td>
    </tr>
  </table>
</p>

---

## Features

* **Responsive Layout:** Automatically switches between Portrait (vertical) and Landscape (horizontal) layouts when you resize it.
* **System Color Matching:** Inherits your system's global accent color to build beautiful color gradients automatically, or you can pick your own solid colors manually.
* **Hour Grouping:** Group hourly activity bars into 1h, 2h, 3h, 4h, or 6h blocks so it fits nicely on any size screen.
* **No overlapping bars:** Bar widths scale down automatically on smaller widget sizes so they never overlap.
* **App blacklist:** Keep background services, lockscreens, or krunner from cluttering your top apps list.
* **Offline safety:** Shows a clean retry screen if your local `aw-server` is stopped or unreachable.

---

## Prerequisites

You need **ActivityWatch** running locally on your computer:

1. **Install ActivityWatch**: Refer to the [Official ActivityWatch Website](https://activitywatch.net/) for setup instructions.
   * *Quick tip:* On Arch Linux, run `yay -S activitywatch-bin`. On Fedora, run `sudo dnf install activitywatch`. For Debian/Ubuntu, download the package from the [ActivityWatch Releases page](https://github.com/ActivityWatch/activitywatch/releases).
2. **Start the service**: Start `aw-qt` (or run it as a background service). Make sure you can open the dashboard at [http://localhost:5600](http://localhost:5600).

---

## Installation

### Method 1: Get New Widgets (Easiest)
You can find it on the [KDE Store page](https://store.kde.org/p/2361910/) or install it directly through KDE:
1. Right-click your desktop and choose **Add Widgets...**
2. Click **Get New Widgets** -> **Download New Plasma Widgets**.
3. Search for **Screentide** and click **Install**.

### Method 2: From Source (CLI)
To clone and install it using the native KDE package manager:
```bash
# Clone this repository
git clone https://github.com/Agarwalpratyaksh/Screentide.git
cd Screentide

# Install the package
kpackagetool6 --type Plasma/Applet --install .

# To update/upgrade the widget later:
kpackagetool6 --type Plasma/Applet --upgrade .
```

### Method 3: Direct `.plasmoid` installation
If you downloaded the compiled `screentide.plasmoid` package directly:
```bash
# Install the package
kpackagetool6 --type Plasma/Applet --install screentide.plasmoid

# To update/upgrade:
kpackagetool6 --type Plasma/Applet --upgrade screentide.plasmoid
```

### Method 4: Manual Copy (Alternative)
If you prefer putting the files in place yourself:
```bash
mkdir -p ~/.local/share/plasma/plasmoids/org.kde.screentide.widget
git clone https://github.com/Agarwalpratyaksh/Screentide.git
cp -r Screentide/* ~/.local/share/plasma/plasmoids/org.kde.screentide.widget/
```

---

## Setup & Customization

Right-click the widget and click **"Configure Screentide..."** to open the settings panel:
* **Background & Borders:** Modify opacity, margins, borders, and corner radius.
* **Layout:** Adjust list limits, bar sizes, and hour grouping intervals.
* **Fonts:** Customize font sizes or override the font family.
* **Filters:** Exclude background apps (e.g. `krunner, lockscreen, plasmashell`).
* **Day Start:** Adjust what hour your tracking day resets (e.g. starting at 6:00 AM instead of midnight).

---

## Local Development & Testing

If you want to modify the code and test your changes:

```bash
# 1. Sync your changes to the local widget directory
cp -rv * ~/.local/share/plasma/plasmoids/org.kde.screentide.widget/

# 2. Clear QML cache and refresh KDE package paths
rm -rf ~/.cache/qmlcache/* && kbuildsycoca6

# 3. Restart the Plasma shell to load changes
plasmashell --replace & disown
```

---

## License

Distributed under the [MIT License](LICENSE).
