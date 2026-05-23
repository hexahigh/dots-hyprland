pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property string vocabPath: FileUtils.trimFileProtocol(`${Directories.assetsPath}/data/chinese_vocab_list.json`)
    readonly property int refreshIntervalMs: Math.max(1, Config.options.background.widgets.chineseWord.refreshIntervalHours) * 60 * 60 * 1000
    readonly property int pollIntervalMs: Math.min(refreshIntervalMs, 60 * 60 * 1000)
    readonly property bool enabled: Config.options.background.widgets.chineseWord.enable

    property var vocabList: []
    property var data: ({
            chinese: "",
            pinyin: "",
            english: "",
            lastRefresh: "",
            source: ""
        })

    function currentDate() {
        return DateTime.clock?.date ?? new Date();
    }

    function dateKey(date) {
        const year = String(date.getFullYear());
        const month = String(date.getMonth() + 1).padStart(2, "0");
        const day = String(date.getDate()).padStart(2, "0");
        return `${year}-${month}-${day}`;
    }

    function seedFromDate(date) {
        const key = dateKey(date);
        let seed = 2166136261;
        for (let i = 0; i < key.length; i++) {
            seed ^= key.charCodeAt(i);
            seed = Math.imul(seed, 16777619);
        }
        return seed >>> 0;
    }

    function seededIndex(seed, length) {
        if (length <= 0)
            return 0;
        let value = seed >>> 0;
        value ^= value << 13;
        value ^= value >>> 17;
        value ^= value << 5;
        return (value >>> 0) % length;
    }

    function dayOfYear(date) {
        const start = new Date(date.getFullYear(), 0, 0);
        const diff = date - start + (start.getTimezoneOffset() - date.getTimezoneOffset()) * 60 * 1000;
        return Math.floor(diff / 86400000);
    }

    function pickEnglish(entry) {
        if (!entry)
            return "";
        if (entry.english)
            return String(entry.english);
        if (entry.eng)
            return String(entry.eng);
        if (Array.isArray(entry.defs) && entry.defs.length > 0)
            return String(entry.defs[0]);
        if (Array.isArray(entry.example_sentences) && entry.example_sentences.length > 0)
            return String(entry.example_sentences[0]?.eng ?? "");
        return "";
    }

    function updateData(chinese, pinyin, english) {
        root.data = {
            chinese: chinese,
            pinyin: pinyin,
            english: english,
            lastRefresh: DateTime.time + " - " + DateTime.date,
            source: root.vocabPath
        };
    }

    function selectDailyEntry() {
        if (!root.vocabList || root.vocabList.length === 0)
            return;
        const today = currentDate();
        const index = seededIndex(seedFromDate(today), root.vocabList.length);
        const entry = root.vocabList[index] ?? {};
        const chinese = String(entry.simp ?? "").trim();
        const pinyin = String(entry.pinyin ?? "").trim();
        const english = String(pickEnglish(entry) ?? "").trim();
        if (chinese.length === 0 && english.length === 0)
            return;
        updateData(chinese, pinyin, english);
    }

    function scheduleNextMidnight() {
        if (!root.enabled)
            return;
        const now = currentDate();
        const next = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
        midnightTimer.interval = Math.max(1000, next - now + 500);
        midnightTimer.restart();
    }

    function loadVocab(text) {
        if (!text || text.length === 0)
            return;
        try {
            const parsed = JSON.parse(text);
            if (!Array.isArray(parsed))
                return;
            root.vocabList = parsed.filter(entry => String(entry?.simp ?? "").trim().length > 0);
            root.selectDailyEntry();
            root.scheduleNextMidnight();
        } catch (e) {
            console.error("[DailyChineseWord] " + e.message);
        }
    }

    onEnabledChanged: {
        if (root.enabled) {
            root.selectDailyEntry();
            root.scheduleNextMidnight();
        } else {
            midnightTimer.stop();
        }
    }

    FileView {
        id: vocabFileView
        path: Qt.resolvedUrl(root.vocabPath)
        watchChanges: true
        onLoaded: root.loadVocab(vocabFileView.text())
        onFileChanged: vocabFileView.reload()
        onLoadFailed: error => {
            console.error("[DailyChineseWord] Failed to load vocab file: " + error);
        }
    }

    Timer {
        id: refreshTimer
        running: root.enabled
        repeat: true
        interval: root.pollIntervalMs
        triggeredOnStart: root.enabled
        onTriggered: root.selectDailyEntry()
    }

    Timer {
        id: midnightTimer
        repeat: false
        onTriggered: {
            root.selectDailyEntry();
            root.scheduleNextMidnight();
        }
    }
}
