import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root
    
    // Disable default system background shadow/glow to prevent double-borders
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    
    property int triggerUpdate: 0
    property string totalTimeStr: "..."
    property int dayOffset: 0
    property string dateLabel: "Today"
    property var dataCache: ({})
    property real maxAppDuration: 1
    
    // Offline status tracking
    property bool isServerOffline: false
    
    // Custom font configuration
    property string customFontFamily: plasmoid.configuration.fontFamily !== "" ? plasmoid.configuration.fontFamily : Kirigami.Theme.defaultFont.family
    
    // Resolved color options (either system theme accent colors or custom settings colors)
    readonly property color resolvedBarColorStart: plasmoid.configuration.useSystemTheme ? Kirigami.Theme.highlightColor : plasmoid.configuration.chartBarColorStart
    readonly property color resolvedBarColorEnd: plasmoid.configuration.useSolidColor ? resolvedBarColorStart : (plasmoid.configuration.useSystemTheme ? Qt.lighter(Kirigami.Theme.highlightColor, 1.25) : plasmoid.configuration.chartBarColorEnd)
    
    readonly property color resolvedBarColorHoverStart: plasmoid.configuration.useSystemTheme ? Qt.lighter(Kirigami.Theme.highlightColor, 1.15) : plasmoid.configuration.chartBarColorHoverStart
    readonly property color resolvedBarColorHoverEnd: plasmoid.configuration.useSolidColor ? resolvedBarColorHoverStart : (plasmoid.configuration.useSystemTheme ? Qt.lighter(Kirigami.Theme.highlightColor, 1.35) : plasmoid.configuration.chartBarColorHoverEnd)
    
    // Define icon mappings once to avoid recreating the array on every call
    readonly property var iconMappings: [
        // Browsers
        { keys: ["chrome"], icon: "google-chrome" },
        { keys: ["brave"], icon: "brave-browser" },
        { keys: ["firefox"], icon: "firefox" },
        { keys: ["edge", "msedge"], icon: "microsoft-edge" },
        { keys: ["opera"], icon: "opera" },
        { keys: ["vivaldi"], icon: "vivaldi" },
        { keys: ["tor"], icon: "tor-browser" },
        { keys: ["safari"], icon: "safari" },
        { keys: ["chromium"], icon: "chromium" },
        
        // IDE / Development
        { keys: ["code", "vscode"], icon: "visual-studio-code" },
        { keys: ["cursor"], icon: "cursor" },
        { keys: ["intellij", "idea"], icon: "intellij-idea" },
        { keys: ["webstorm"], icon: "webstorm" },
        { keys: ["pycharm"], icon: "pycharm" },
        { keys: ["clion"], icon: "clion" },
        { keys: ["android", "studio"], icon: "android-studio" },
        { keys: ["sublime", "subl"], icon: "sublime-text" },
        { keys: ["emacs"], icon: "emacs" },
        { keys: ["neovim", "nvim"], icon: "nvim" },
        { keys: ["vim"], icon: "vim" },
        { keys: ["gitkraken"], icon: "gitkraken" },
        { keys: ["github"], icon: "github" },
        
        // Terminals
        { keys: ["kitty"], icon: "kitty" },
        { keys: ["alacritty"], icon: "alacritty" },
        { keys: ["konsole"], icon: "konsole" },
        { keys: ["wezterm"], icon: "wezterm" },
        { keys: ["terminal", "term", "bash", "zsh"], icon: "utilities-terminal" },
        
        // Communication
        { keys: ["slack"], icon: "slack" },
        { keys: ["discord"], icon: "discord" },
        { keys: ["telegram"], icon: "telegram" },
        { keys: ["whatsapp"], icon: "whatsapp" },
        { keys: ["teams"], icon: "teams" },
        { keys: ["signal"], icon: "signal" },
        { keys: ["zoom"], icon: "zoom" },
        { keys: ["skype"], icon: "skype" },
        
        // Email
        { keys: ["thunderbird"], icon: "thunderbird" },
        { keys: ["evolution"], icon: "evolution" },
        { keys: ["kmail"], icon: "kmail" },
        
        // Office & Productivity
        { keys: ["writer"], icon: "libreoffice-writer" },
        { keys: ["calc"], icon: "libreoffice-calc" },
        { keys: ["impress"], icon: "libreoffice-impress" },
        { keys: ["notion"], icon: "notion" },
        { keys: ["obsidian"], icon: "obsidian" },
        { keys: ["evernote"], icon: "evernote" },
        { keys: ["todoist"], icon: "todoist" },
        
        // Creative & Media
        { keys: ["blender"], icon: "blender" },
        { keys: ["gimp"], icon: "gimp" },
        { keys: ["inkscape"], icon: "inkscape" },
        { keys: ["krita"], icon: "krita" },
        { keys: ["photoshop"], icon: "photoshop" },
        { keys: ["illustrator"], icon: "illustrator" },
        { keys: ["figma"], icon: "figma" },
        { keys: ["spotify"], icon: "spotify" },
        { keys: ["vlc"], icon: "vlc" },
        { keys: ["mpv"], icon: "mpv" },
        { keys: ["steam"], icon: "steam" },
        { keys: ["lutris"], icon: "lutris" },
        { keys: ["heroic"], icon: "heroic" },
        
        // System / Utilities
        { keys: ["dolphin", "finder"], icon: "system-file-manager" },
        { keys: ["settings", "preferences", "control-center"], icon: "preferences-system" },
        { keys: ["discover"], icon: "plasmadiscover" },
        { keys: ["systemmonitor", "htop", "monitor"], icon: "utilities-system-monitor" },
        { keys: ["krunner"], icon: "krunner" },
        { keys: ["spectacle", "screenshot"], icon: "spectacle" }
    ]
    
    property var iconExactCache: ({})
    
    onDayOffsetChanged: {
        updateDateLabel();
        fetchData();
    }
    
    // Watch configuration changes and reload data when relevant settings change
    Connections {
        target: plasmoid.configuration
        function onStartHourChanged() {
            root.dataCache = {};
            root.fetchData();
        }
        function onMaxAppsShownChanged() {
            root.dataCache = {};
            root.fetchData();
        }
        function onShowPercentagesChanged() {
            root.dataCache = {};
            root.fetchData();
        }
        function onBlacklistChanged() {
            root.dataCache = {};
            root.fetchData();
        }
        function onHourStepIndexChanged() {
            root.dataCache = {};
            root.fetchData();
        }
    }
    
    function updateDateLabel() {
        if (dayOffset === 0) {
            dateLabel = "Today";
        } else if (dayOffset === -1) {
            dateLabel = "Yesterday";
        } else {
            var d = new Date();
            d.setDate(d.getDate() + dayOffset);
            dateLabel = d.toLocaleDateString(Qt.locale(), Locale.ShortFormat);
        }
    }
    
    readonly property int hourStep: {
        var steps = [1, 2, 3, 4, 6];
        var idx = plasmoid.configuration.hourStepIndex;
        return (idx >= 0 && idx < steps.length) ? steps[idx] : 1;
    }
    
    property var hourlyData: []
    property real maxHourlyTime: 1
    
    ListModel { id: appsModel }
    
    Timer {
        id: autoRefreshTimer
        interval: 300000 // 5 minutes
        running: true
        repeat: true
        onTriggered: fetchData()
    }
    
    Component.onCompleted: {
        var cache = {};
        for (var i = 0; i < iconMappings.length; i++) {
            var entry = iconMappings[i];
            for (var j = 0; j < entry.keys.length; j++) {
                cache[entry.keys[j]] = entry.icon;
            }
        }
        iconExactCache = cache;
        fetchData();
    }
    
    function formatDuration(seconds) {
        var hrs = Math.floor(seconds / 3600);
        var mins = Math.floor((seconds % 3600) / 60);
        if (hrs > 0) return hrs + "h " + mins + "m";
        if (mins > 0) return mins + "m";
        return Math.floor(seconds) + "s";
    }

    function getHourLabel(index) {
        var startHour = plasmoid.configuration.startHour
        var step = root.hourStep
        var startHr = (index * step + startHour) % 24;
        var endHr = ((index + 1) * step + startHour) % 24;
        return formatHourHelper(startHr) + " - " + formatHourHelper(endHr);
    }
    
    function formatHourHelper(h) {
        if (h === 0) return "12 AM";
        if (h === 12) return "12 PM";
        return (h > 12) ? (h - 12) + " PM" : h + " AM";
    }

    function mapIcon(appName) {
        appName = appName.toLowerCase()
        
        // 1. Exact match lookup cache
        if (iconExactCache[appName] !== undefined) {
            return iconExactCache[appName];
        }
        
        // 2. Fallback to substring checking
        for (var i = 0; i < iconMappings.length; i++) {
            var entry = iconMappings[i];
            for (var j = 0; j < entry.keys.length; j++) {
                if (appName.indexOf(entry.keys[j]) !== -1) {
                    return entry.icon;
                }
            }
        }
        
        // Extract icon from desktop app namespace (e.g. org.kde.kcalc -> kcalc)
        if (appName.indexOf(".") !== -1) {
            var parts = appName.split(".");
            var lastPart = parts[parts.length - 1];
            if (lastPart.length > 0) return lastPart;
        }
        
        if (appName.length > 0 && appName !== "unknown") {
            return appName;
        }
        
        return "system-run"
    }

    function fetchData() {
        if (root.dayOffset < 0 && root.dataCache[root.dayOffset] !== undefined) {
            var cached = root.dataCache[root.dayOffset];
            root.totalTimeStr = cached.totalTimeStr;
            root.hourlyData = cached.hourlyData;
            root.maxHourlyTime = cached.maxHourlyTime;
            root.maxAppDuration = cached.maxAppDuration;
            
            appsModel.clear();
            for (var i = 0; i < cached.apps.length; i++) {
                appsModel.append(cached.apps[i]);
            }
            root.triggerUpdate += 1;
            return;
        }

        var xhr = new XMLHttpRequest()
        xhr.open("POST", "http://127.0.0.1:5600/api/0/query/")
        xhr.setRequestHeader("Content-Type", "application/json")
        
        var startHour = plasmoid.configuration.startHour
        var now = new Date()
        var logicalNow = new Date(now.getTime() - startHour * 3600 * 1000)
        var targetDate = new Date(logicalNow.getFullYear(), logicalNow.getMonth(), logicalNow.getDate() + root.dayOffset)
        
        var startOfDay = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate(), startHour, 0, 0, 0)
        var endOfDay = new Date(startOfDay.getTime() + 24 * 3600 * 1000 - 1)
        
        var query = "afk = query_bucket(find_bucket(\"aw-watcher-afk_\"));\n" +
                    "window = query_bucket(find_bucket(\"aw-watcher-window_\"));\n" +
                    "not_afk = filter_keyvals(afk, \"status\", [\"not-afk\"]);\n" +
                    "active_window = filter_period_intersect(window, not_afk);\n" +
                    "RETURN = active_window;"
                    
        var payload = { "query": [query], "timeperiods": [startOfDay.toISOString() + "/" + endOfDay.toISOString()] }
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    root.isServerOffline = false;
                    var response = JSON.parse(xhr.responseText)
                    var resultEvents = response[0]
                    if (resultEvents && resultEvents.length > 0 && Array.isArray(resultEvents[0])) resultEvents = resultEvents[0]
                    if (!resultEvents || !resultEvents.length) resultEvents = []
                    
                    var totalSecs = 0
                    var step = root.hourStep
                    var binCount = Math.ceil(24 / step)
                    var hourBins = []
                    for (var bIdx = 0; bIdx < binCount; bIdx++) hourBins.push(0)
                    var appMap = {}
                    
                    // Parse ignore filter
                    var blacklistStr = plasmoid.configuration.blacklist.toLowerCase();
                    var blacklistArr = blacklistStr.split(",").map(function(s) {
                        return s.trim();
                    }).filter(Boolean);
                    
                    for (var i = 0; i < resultEvents.length; i++) {
                        var ev = resultEvents[i]
                        var dur = ev.duration
                        var app = ev.data.app || "Unknown"
                        var appLower = app.toLowerCase();
                        
                        // Check exclusions
                        var isBlacklisted = false;
                        for (var b = 0; b < blacklistArr.length; b++) {
                            if (appLower.indexOf(blacklistArr[b]) !== -1) {
                                isBlacklisted = true;
                                break;
                            }
                        }
                        if (isBlacklisted) continue;
                        
                        totalSecs += dur
                        
                        if (appMap[app] === undefined) appMap[app] = 0
                        appMap[app] += dur
                        
                        var evDate = new Date(ev.timestamp)
                        var hr = evDate.getHours()
                        var mappedHr = (hr >= startHour) ? (hr - startHour) : (hr + 24 - startHour)
                        if (mappedHr >= 0 && mappedHr < 24) {
                            var binIndex = Math.floor(mappedHr / step)
                            if (binIndex >= 0 && binIndex < binCount) {
                                hourBins[binIndex] += dur
                            }
                        }
                    }
                    
                    root.totalTimeStr = formatDuration(totalSecs)
                    root.hourlyData = hourBins
                    
                    var m = 1
                    for (var h = 0; h < binCount; h++) if (hourBins[h] > m) m = hourBins[h]
                    root.maxHourlyTime = m
                    
                    var sortable = []
                    for (var a in appMap) sortable.push([a, appMap[a]])
                    sortable.sort(function(a, b) { return b[1] - a[1] })
                    
                    if (sortable.length > 0) {
                        root.maxAppDuration = sortable[0][1];
                    } else {
                        root.maxAppDuration = 1;
                    }
                    
                    appsModel.clear()
                    var maxApps = Math.min(plasmoid.configuration.maxAppsShown, sortable.length)
                    var appListForCache = [];
                    
                    for (var k = 0; k < maxApps; k++) {
                        var appName = sortable[k][0];
                        var appDur = sortable[k][1];
                        var icon = mapIcon(appName);
                        var durationStr = formatDuration(appDur);
                        var pct = totalSecs > 0 ? Math.round((appDur / totalSecs) * 100) : 0;
                        var pctStr = pct + "%";
                        
                        appsModel.append({
                            "name": appName,
                            "durationStr": durationStr,
                            "percentageStr": pctStr,
                            "iconName": icon,
                            "rawDuration": appDur
                        });
                        
                        if (root.dayOffset < 0) {
                            appListForCache.push({
                                "name": appName,
                                "durationStr": durationStr,
                                "percentageStr": pctStr,
                                "iconName": icon,
                                "rawDuration": appDur
                            });
                        }
                    }
                    
                    if (root.dayOffset < 0) {
                        root.dataCache[root.dayOffset] = {
                            "totalTimeStr": root.totalTimeStr,
                            "hourlyData": root.hourlyData,
                            "maxHourlyTime": root.maxHourlyTime,
                            "maxAppDuration": root.maxAppDuration,
                            "apps": appListForCache
                        };
                    }
                    
                    root.triggerUpdate += 1
                } else {
                    // Server Offline / Unreachable
                    root.isServerOffline = true;
                    root.totalTimeStr = "Offline";
                    var offlineBins = [];
                    var offlineStep = root.hourStep;
                    var offlineBinCount = Math.ceil(24 / offlineStep);
                    for (var oIdx = 0; oIdx < offlineBinCount; oIdx++) offlineBins.push(0);
                    root.hourlyData = offlineBins;
                    root.maxHourlyTime = 1;
                    appsModel.clear();
                    root.triggerUpdate += 1;
                }
            }
        }
        xhr.send(JSON.stringify(payload))
    }
    
    // --- Reusable Sub-Components ---
    
    Component {
        id: appItemDelegate
        Item {
            id: delegateRoot
            width: ListView.view ? ListView.view.width : (parent ? parent.width : 0)
            height: 44
            
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            
            Rectangle {
                anchors.fill: parent
                color: itemHover.containsMouse ? "#2C2C2E" : "transparent"
                radius: 8
                Behavior on color { ColorAnimation { duration: 100 } }
                
                MouseArea {
                    id: itemHover
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10
                
                Kirigami.Icon {
                    source: model.iconName
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                }
                
                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: model.name
                            color: "white"
                            font.family: root.customFontFamily
                            font.pixelSize: Math.max(9, 13 + plasmoid.configuration.fontSizeModifier)
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: plasmoid.configuration.showPercentages ? (model.durationStr + " (" + model.percentageStr + ")") : model.durationStr
                            color: "#98989D"
                            font.family: root.customFontFamily
                            font.pixelSize: Math.max(8, 11 + plasmoid.configuration.fontSizeModifier)
                            font.weight: Font.Medium
                        }
                    }
                    
                    // Progress bar showing relative share
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 3
                        color: "#2C2C2E"
                        radius: 1.5
                        
                        Rectangle {
                            width: (root.maxAppDuration > 0 && model.rawDuration !== undefined) ? (model.rawDuration / root.maxAppDuration) * parent.width : 0
                            height: parent.height
                            radius: 1.5
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: root.resolvedBarColorStart }
                                GradientStop { position: 1.0; color: root.resolvedBarColorEnd }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: navControlsComponent
        RowLayout {
            spacing: 8
            
            // Nav Buttons
            Rectangle {
                Layout.preferredHeight: 32
                Layout.preferredWidth: navRow.implicitWidth + 24
                radius: 16
                color: "#2C2C2E"
                
                RowLayout {
                    id: navRow
                    anchors.centerIn: parent
                    spacing: 12
                    
                    // Left Arrow Character
                    Text {
                        text: "‹"
                        color: mouseAreaLeftArrow.containsMouse ? plasmoid.configuration.chartBarColorStart : "white"
                        font.family: root.customFontFamily
                        font.pixelSize: Math.max(10, 20 + plasmoid.configuration.fontSizeModifier)
                        font.weight: Font.Bold
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        
                        Behavior on color { ColorAnimation { duration: 100 } }
                        
                        MouseArea {
                            id: mouseAreaLeftArrow
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.dayOffset--
                            anchors.margins: -8
                        }
                    }
                    
                    Text {
                        text: root.dateLabel
                        color: "#98989D"
                        font.family: root.customFontFamily
                        font.pixelSize: Math.max(9, 13 + plasmoid.configuration.fontSizeModifier)
                        font.weight: Font.DemiBold
                    }
                    
                    // Right Arrow Character
                    Text {
                        text: "›"
                        color: root.dayOffset < 0 ? (mouseAreaRightArrow.containsMouse ? plasmoid.configuration.chartBarColorStart : "white") : "#555555"
                        font.family: root.customFontFamily
                        font.pixelSize: Math.max(10, 20 + plasmoid.configuration.fontSizeModifier)
                        font.weight: Font.Bold
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        
                        Behavior on color { ColorAnimation { duration: 100 } }
                        
                        MouseArea {
                            id: mouseAreaRightArrow
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.dayOffset < 0
                            cursorShape: root.dayOffset < 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.dayOffset++
                            anchors.margins: -8
                        }
                    }
                }
            }
            
            // Refresh Button
            Rectangle {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 32
                radius: 16
                color: mouseAreaRefresh.containsMouse ? "#3A3A3C" : "#2C2C2E"
                Behavior on color { ColorAnimation { duration: 100 } }
                
                Kirigami.Icon {
                    source: "view-refresh"
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    color: "white"
                    isMask: true
                }
                
                MouseArea {
                    id: mouseAreaRefresh
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.dataCache = {};
                        root.fetchData();
                    }
                }
            }
        }
    }

    Component {
        id: chartComponent
        Item {
            id: chartRoot
            width: parent ? parent.width : 0
            height: parent ? parent.height : 0
            
            property real graphWidth: width - 40
            property real graphHeight: height - 20
            
            // Y-axis lines
            Repeater {
                model: 3
                Item {
                    width: chartRoot.width
                    height: 1
                    y: index * (chartRoot.graphHeight / 2)
                    
                    Rectangle {
                        width: chartRoot.graphWidth
                        height: 1
                        color: "#2C2C2E" // Soft grid color
                    }
                    
                    Text {
                        text: index === 0 ? formatDuration(root.maxHourlyTime) : (index === 1 ? formatDuration(root.maxHourlyTime / 2) : "0")
                        color: "#8E8E93"
                        font.family: root.customFontFamily
                        font.pixelSize: Math.max(8, 10 + plasmoid.configuration.fontSizeModifier)
                        font.weight: Font.DemiBold
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.top
                    }
                }
            }
            
            // X-axis dashes
            Repeater {
                model: 4
                Item {
                    property int hourIndex: index * 6
                    x: (hourIndex / 24) * chartRoot.graphWidth
                    y: 0
                    width: 1
                    height: chartRoot.graphHeight
                    
                    Column {
                        spacing: 4
                        Repeater {
                            model: chartRoot.graphHeight / 6
                            Rectangle { width: 1; height: 2; color: "#2C2C2E" }
                        }
                    }
                    
                    Text {
                        text: {
                            var hr = (index * 6 + plasmoid.configuration.startHour) % 24;
                            return formatHourHelper(hr);
                        }
                        color: "#8E8E93"
                        font.family: root.customFontFamily
                        font.pixelSize: Math.max(8, 10 + plasmoid.configuration.fontSizeModifier)
                        font.weight: Font.DemiBold
                        anchors.top: parent.top
                        anchors.topMargin: chartRoot.graphHeight + 6
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                    }
                }
            }
            
            // Bars & Hover
            Repeater {
                model: root.hourlyData.length
                Item {
                    x: (index / root.hourlyData.length) * chartRoot.graphWidth
                    y: 0
                    width: chartRoot.graphWidth / root.hourlyData.length
                    height: chartRoot.graphHeight
                    
                    Rectangle {
                        id: visualBar
                        property real val: root.hourlyData[index] + (root.triggerUpdate * 0)
                        property real barHeight: val > 0 ? Math.max(2, (val / root.maxHourlyTime) * chartRoot.graphHeight) : 0
                        
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.max(1, Math.min(plasmoid.configuration.barWidth, parent.width - 2))
                        height: barHeight
                        radius: plasmoid.configuration.barRadius
                        
                        // Configurable gradient colors
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: mouseArea.containsMouse ? root.resolvedBarColorHoverStart : root.resolvedBarColorStart }
                            GradientStop { position: 1.0; color: mouseArea.containsMouse ? root.resolvedBarColorHoverEnd : root.resolvedBarColorEnd }
                        }
                        
                        Behavior on height {
                            NumberAnimation { duration: 500; easing.type: Easing.OutQuint }
                        }
                    }
                    
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: {
                            if (containsMouse) {
                                tooltipBubble.hoveredIndex = index;
                            } else if (tooltipBubble.hoveredIndex === index) {
                                tooltipBubble.hoveredIndex = -1;
                            }
                        }
                    }
                }
            }
            
            // Declarative Tooltip Bubble
            Rectangle {
                id: tooltipBubble
                property int hoveredIndex: -1
                visible: hoveredIndex !== -1
                color: "#2C2C2E"
                border.color: "#48484A"
                border.width: 1
                radius: 6
                width: Math.max(80, tooltipText.implicitWidth + 16)
                height: tooltipText.implicitHeight + 10
                z: 100
                
                x: {
                    if (hoveredIndex === -1) return 0;
                    var colX = (hoveredIndex / 24) * chartRoot.graphWidth;
                    var colWidth = chartRoot.graphWidth / 24;
                    var targetX = colX + (colWidth - width) / 2;
                    return Math.max(0, Math.min(chartRoot.graphWidth - width, targetX));
                }
                
                y: {
                    if (hoveredIndex === -1) return 0;
                    var val = root.hourlyData[hoveredIndex];
                    var barHeight = val > 0 ? Math.max(2, (val / root.maxHourlyTime) * chartRoot.graphHeight) : 0;
                    var barTop = chartRoot.graphHeight - barHeight;
                    return Math.max(0, barTop - height - 6);
                }
                
                Text {
                    id: tooltipText
                    text: tooltipBubble.hoveredIndex !== -1 ? (getHourLabel(tooltipBubble.hoveredIndex) + "\n" + formatDuration(root.hourlyData[tooltipBubble.hoveredIndex])) : ""
                    color: "white"
                    font.family: root.customFontFamily
                    font.pixelSize: Math.max(8, 11 + plasmoid.configuration.fontSizeModifier)
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    anchors.centerIn: parent
                }
            }
        }
    }
    
    compactRepresentation: MouseArea {
        id: compactRoot
        
        onClicked: root.expanded = !root.expanded
        
        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing
            
            Kirigami.Icon {
                source: "view-time-schedule"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                isMask: true
            }
            
            PlasmaComponents.Label {
                text: root.totalTimeStr
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize + plasmoid.configuration.fontSizeModifier
                font.family: root.customFontFamily
                visible: compactRoot.width > (Kirigami.Units.iconSizes.small * 2.5)
                elide: Text.ElideRight
            }
        }
    }
    
    fullRepresentation: Item {
        id: fullRep
        
        Layout.minimumWidth: 320
        Layout.minimumHeight: 280
        Layout.preferredWidth: 400
        Layout.preferredHeight: 340
        
        property bool isLandscape: width >= 480 && width > height * 1.1
        
        // Background card placed as sibling so opacity doesn't affect child layout text/icons
        Rectangle {
            anchors.fill: parent
            color: plasmoid.configuration.backgroundColor
            radius: plasmoid.configuration.borderRadius
            border.color: plasmoid.configuration.borderColor
            border.width: plasmoid.configuration.borderWidth
            opacity: plasmoid.configuration.backgroundOpacity
            z: -1
        }
        
        // Offline Warning Overlay
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12
            visible: root.isServerOffline
            
            Item { Layout.fillHeight: true }
            
            Kirigami.Icon {
                source: "network-disconnect"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                color: "#FF453A"
                isMask: true
            }
            
            Text {
                text: "ActivityWatch Offline"
                color: "white"
                font.family: root.customFontFamily
                font.pixelSize: 16
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignHCenter
            }
            
            Text {
                text: "Make sure aw-server is running at http://localhost:5600"
                color: "#8E8E93"
                font.family: root.customFontFamily
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: parent.width * 0.8
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.Wrap
            }
            
            Item { Layout.preferredHeight: 8 }
            
            // Retry Button
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 32
                Layout.preferredWidth: 100
                radius: 16
                color: mouseAreaRetryOffline.containsMouse ? "#3A3A3C" : "#2C2C2E"
                
                Text {
                    anchors.centerIn: parent
                    text: "Retry"
                    color: "white"
                    font.family: root.customFontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                
                MouseArea {
                    id: mouseAreaRetryOffline
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.dataCache = {};
                        root.fetchData();
                    }
                }
            }
            
            Item { Layout.fillHeight: true }
        }
        
        // Vertical Layout (Portrait)
        ColumnLayout {
            id: portraitLayout
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14
            visible: !fullRep.isLandscape && !root.isServerOffline
            
            // Header Row
            RowLayout {
                Layout.fillWidth: true
                visible: plasmoid.configuration.showHeader
                
                Text {
                    text: root.totalTimeStr
                    color: "white"
                    font.family: root.customFontFamily
                    // Dynamically scale font size based on layout width to prevent clipping
                    font.pixelSize: Math.min(32, Math.max(16, portraitLayout.width * 0.08)) + plasmoid.configuration.fontSizeModifier
                    font.weight: Font.DemiBold
                }
                
                Item { Layout.fillWidth: true }
                
                Loader {
                    sourceComponent: navControlsComponent
                }
            }
            
            // Chart Area (Scales dynamically based on parent height)
            Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(80, Math.min(220, portraitLayout.height * 0.35))
                Layout.fillHeight: true
                sourceComponent: chartComponent
            }
            
            Item { Layout.preferredHeight: 16 }
            
            // Apps Grid (Adaptive column count based on widget width)
            GridLayout {
                columns: portraitLayout.width >= 360 ? 2 : 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                rowSpacing: 14
                columnSpacing: 24
                
                Repeater {
                    model: appsModel
                    delegate: appItemDelegate
                }
            }
        }
        
        // Horizontal Layout (Landscape)
        RowLayout {
            id: landscapeLayout
            anchors.fill: parent
            anchors.margins: 20
            spacing: 24
            visible: fullRep.isLandscape && !root.isServerOffline
            
            // Left pane (Header & Chart)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14
                
                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    visible: plasmoid.configuration.showHeader
                    
                    Text {
                        text: root.totalTimeStr
                        color: "white"
                        font.family: root.customFontFamily
                        font.pixelSize: Math.min(32, Math.max(16, landscapeLayout.width * 0.05)) + plasmoid.configuration.fontSizeModifier
                        font.weight: Font.DemiBold
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Loader {
                        sourceComponent: navControlsComponent
                    }
                }
                
                // Chart Area
                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sourceComponent: chartComponent
                }
            }
            
            // Right pane (Apps List - scales dynamically with widget width)
            ColumnLayout {
                Layout.preferredWidth: Math.max(150, Math.min(300, landscapeLayout.width * 0.35))
                Layout.fillHeight: true
                spacing: 10
                
                Text {
                    text: "Top Apps"
                    color: "#98989D"
                    font.family: root.customFontFamily
                    font.pixelSize: Math.max(9, 13 + plasmoid.configuration.fontSizeModifier)
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: appsModel
                    spacing: 8
                    delegate: appItemDelegate
                }
            }
        }
    }
}