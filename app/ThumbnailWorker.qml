import QtQuick
import "Ds" as Ds

// M2 thumbnail worker stub: async prefetch queue in front of
// LibraryService.requestThumbnail. Real frame decode + SQLite-backed disk
// cache lands in a later milestone; cards paint a deterministic gradient +
// Canvas placeholder immediately so the grid stays virtualized.
// (Item root with visible:false so it can own the Timer yet stay out of
// layouts; QtObject has no default property for child objects.)
Item {
    id: worker
    visible: false

    signal ready(string path, string hint)

    property var _queue: []
    property bool _busy: false

    function hintFor(path) {
        var palette = Ds.Theme.artPalette;
        var h = 0;
        for (var i = 0; i < path.length; ++i)
            h = (h * 31 + path.charCodeAt(i)) % 100000;
        return palette[h % palette.length];
    }

    function request(path) {
        if (!path)
            return;
        if (_queue.indexOf(path) !== -1)
            return;
        _queue.push(path);
        console.log("M2 thumbnail worker: queued", path);
        if (typeof LibraryService !== "undefined" && LibraryService.requestThumbnail)
            LibraryService.requestThumbnail(path);
        kick();
    }

    function kick() {
        if (!_busy && _queue.length > 0) {
            _busy = true;
            pump.start();
        }
    }

    Timer {
        id: pump
        interval: 40
        repeat: false
        onTriggered: {
            var path = worker._queue.length > 0 ? worker._queue.shift() : "";
            worker._busy = false;
            if (path !== "") {
                worker.ready(path, worker.hintFor(path));
                console.log("M2 thumbnail worker: ready", path);
            }
            worker.kick();
        }
    }
}
