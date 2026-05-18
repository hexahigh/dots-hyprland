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

    property var vocabList: []
    property var data: ({
            chinese: "",
            english: "",
            lastRefresh: "",
            source: ""
        })

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

    function updateData(chinese, english) {
        root.data = {
            chinese: chinese,
            english: english,
            lastRefresh: DateTime.time + " - " + DateTime.date,
            source: root.vocabPath
        };
    }

    function selectDailyEntry() {
        if (!root.vocabList || root.vocabList.length === 0)
            return;
        const today = DateTime.clock?.date ?? new Date();
        const index = dayOfYear(today) % root.vocabList.length;
        const entry = root.vocabList[index] ?? {};
        const chinese = String(entry.simp ?? "").trim();
        const english = String(pickEnglish(entry) ?? "").trim();
        if (chinese.length === 0 && english.length === 0)
            return;
        updateData(chinese, english);
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
        } catch (e) {
            console.error("[DailyChineseWord] " + e.message);
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
        running: Config.options.background.widgets.chineseWord.enable
        repeat: true
        interval: refreshIntervalMs
        triggeredOnStart: Config.options.background.widgets.chineseWord.enable
        onTriggered: root.selectDailyEntry()
    }
}
