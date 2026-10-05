pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Takvimdeki günlere bağlı yapılacaklar listesi: ~/.local/state/quickshell/.../todos.json
// { "2026-10-05": [ { id, text, done } ], ... }
Singleton {
    id: todos

    readonly property alias days: adapter.days

    function key(date) {
        const pad = n => (n < 10 ? "0" : "") + n
        return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
    }

    function tasks(date) { return days[key(date)] ?? [] }
    // Takvimde nokta göstermek için: o günün bitmemiş görevi var mı / hiç görevi var mı.
    function pending(date) { return tasks(date).filter(t => !t.done).length }
    function count(date) { return tasks(date).length }

    function add(date, text) {
        text = text.trim()
        if (text === "")
            return
        const id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6)
        write(date, tasks(date).concat([{ id: id, text: text, done: false }]))
    }
    function edit(date, id, text) {
        text = text.trim()
        if (text === "")
            return remove(date, id)
        write(date, tasks(date).map(t => t.id === id ? Object.assign({}, t, { text: text }) : t))
    }
    function toggle(date, id) {
        write(date, tasks(date).map(t => t.id === id ? Object.assign({}, t, { done: !t.done }) : t))
    }
    function remove(date, id) {
        write(date, tasks(date).filter(t => t.id !== id))
    }
    // Sürükle-bırak sonrası yeni sıra (görev kimlikleri).
    function reorder(date, ids) {
        const list = tasks(date)
        const sorted = ids.map(id => list.find(t => t.id === id)).filter(t => t)
        write(date, sorted.concat(list.filter(t => ids.indexOf(t.id) < 0)))
    }
    function clearDone(date) {
        write(date, tasks(date).filter(t => !t.done))
    }

    function write(date, list) {
        const copy = Object.assign({}, adapter.days)
        if (list.length)
            copy[key(date)] = list
        else
            delete copy[key(date)]
        adapter.days = copy
        file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.statePath("todos.json")
        blockLoading: true
        // Dosya elle düzenlenirse de güncel kalsın.
        watchChanges: true
        onFileChanged: reload()
        // İlk çalıştırmada dosya yok: boş haliyle oluştur.
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter()
        }

        JsonAdapter {
            id: adapter
            property var days: ({})
        }
    }
}
