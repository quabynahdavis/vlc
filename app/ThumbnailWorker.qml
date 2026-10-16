import QtQuick
import "Ds" as Ds

// M5 thumbnail worker: LRU-200 hint cache + background pool stub in front
// of LibraryService.requestThumbnail. Real frame decode + SQLite disk cache
// lands later; cards paint a deterministic gradient + Canvas placeholder
// immediately so the grid stays virtualized at 60fps @1k rows.
// Cache: _cache[path] -> hint, _lru MRU-last, capped at cacheCapacity (200).
// Pool: pump drains up to poolSize completions per tick, emulating a
// QThreadPool(4) without spawning threads in QML (real pool lands in C++).
// Scan watcher stub: startScan(folder) simulates a folder sweep with
// scanProgress 0..1 so LibraryView can show a progress bar; real
// QFileSystemWatcher + SQLite upsert lands later.
// (Item root with visible:false so it can own Timers yet stay out of
// layouts; QtObject has no default property for child objects.)
Item {
    id: worker
    visible: false

    signal ready(string path, string hint)
    signal cacheHit(string path)
    signal scanStarted(string folder)
    signal scanProgress(string folder, real done, real total)
    signal scanFinished(string folder, int count)

    // M5 perf: LRU cap 200 hints, pool of 4 completions per pump tick.
    property int cacheCapacity: 200
    property int poolSize: 4
    property var _cache: ({})
    property var _lru: []
    property var _queue: []
    property bool _busy: false

    // Scan watcher stub state.
    property bool scanning: false
    property string scanFolder: ""
    property real scanProgressValue: 0
    property int _scanDone: 0
    property int _scanTotal: 20

    function hintFor(path) {
        var palette = Ds.Theme.artPalette;
        var h = 0;
        for (var i = 0; i < path.length; ++i)
            h = (h * 31 + path.charCodeAt(i)) % 100000;
        return palette[h % palette.length];
    }

    function isCached(path) {
        return Object.prototype.hasOwnProperty.call(worker._cache, path);
    }

    function cachedHint(path) {
        return worker._cache[path];
    }

    function cacheSize() {
        return worker._lru.length;
    }

    function clearCache() {
        worker._cache = {};
        worker._lru = [];
        console.log("M5 thumbnail cache cleared (stub)");
    }

    function _touch(path) {
        var i = worker._lru.indexOf(path);
        if (i !== -1)
            worker._lru.splice(i, 1);
        worker._lru.push(path);
    }

    function _store(path, hint) {
        // LRU-200: evict oldest first, then append MRU-last.
        if (!worker.isCached(path) && worker._lru.length >= worker.cacheCapacity) {
            var oldest = worker._lru.shift();
            delete worker._cache[oldest];
            console.log("M5 thumbnail LRU evict:", oldest);
        }
        worker._cache[path] = hint;
        worker._touch(path);
    }

    function request(path) {
        if (!path)
            return;
        // LRU hit: resolve on the next pump tick (still async, no C++ hop).
        if (worker.isCached(path)) {
            worker._touch(path);
            worker.cacheHit(path);
            if (worker._queue.indexOf(path) === -1)
                worker._queue.push(path);
            worker.kick();
            return;
        }
        if (worker._queue.indexOf(path) !== -1)
            return;
        worker._queue.push(path);
        console.log("M5 thumbnail worker: queued", path);
        if (typeof LibraryService !== "undefined" && LibraryService.requestThumbnail)
            LibraryService.requestThumbnail(path);
        worker.kick();
    }

    function kick() {
        if (!worker._busy && worker._queue.length > 0) {
            worker._busy = true;
            pump.start();
        }
    }

    function pumpOne(path) {
        var hint = worker.isCached(path) ? worker.cachedHint(path) : worker.hintFor(path);
        if (!worker.isCached(path))
            worker._store(path, hint);
        worker.ready(path, hint);
        console.log("M5 thumbnail worker: ready", path, hint, "(cache " + worker.cacheSize() + "/" + worker.cacheCapacity + ")");
    }

    // Scan watcher stub: fake a 20-file sweep at ~8 files/sec.
    function startScan(folder) {
        if (worker.scanning) {
            console.log("M5 scan watcher: already scanning", worker.scanFolder);
            return;
        }
        worker.scanning = true;
        worker.scanFolder = folder || "/videos";
        worker._scanDone = 0;
        worker._scanTotal = 20;
        worker.scanProgressValue = 0;
        worker.scanStarted(worker.scanFolder);
        console.log("M5 scan watcher started (stub):", worker.scanFolder);
        try {
            if (typeof LibraryService !== "undefined" && LibraryService.startScan)
                LibraryService.startScan(worker.scanFolder);
        } catch (e) {
            console.log("M5 scan watcher: service startScan failed:", e);
        }
        scanPump.start();
    }

    function stopScan() {
        if (!worker.scanning)
            return;
        scanPump.stop();
        worker.scanning = false;
        worker.scanProgressValue = 0;
        console.log("M5 scan watcher stopped (stub):", worker.scanFolder);
        try {
            if (typeof LibraryService !== "undefined" && LibraryService.stopScan)
                LibraryService.stopScan();
        } catch (e) {
        }
    }

    // Background pool stub: one 16ms tick drains up to poolSize items,
    // emulating 4 parallel decoders; keeps GridView at 60fps @1k rows.
    Timer {
        id: pump
        interval: 16
        repeat: false
        onTriggered: {
            var n = Math.min(worker.poolSize, worker._queue.length);
            for (var i = 0; i < n; ++i) {
                var path = worker._queue.shift();
                if (path !== "")
                    worker.pumpOne(path);
            }
            worker._busy = false;
            worker.kick();
        }
    }

    Timer {
        id: scanPump
        interval: 120
        repeat: true
        running: false
        onTriggered: {
            if (!worker.scanning) {
                scanPump.stop();
                return;
            }
            worker._scanDone += 1;
            worker.scanProgressValue = worker._scanDone / worker._scanTotal;
            worker.scanProgress(worker.scanFolder, worker._scanDone, worker._scanTotal);
            if (worker._scanDone >= worker._scanTotal) {
                scanPump.stop();
                worker.scanning = false;
                worker.scanProgressValue = 1;
                worker.scanFinished(worker.scanFolder, worker._scanTotal);
                console.log("M5 scan watcher finished (stub):", worker.scanFolder, worker._scanTotal, "files");
            }
        }
    }
}
