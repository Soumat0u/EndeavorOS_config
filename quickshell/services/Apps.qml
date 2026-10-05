pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Uygulama başlatıcısının verisi: kurulu uygulamalar (.desktop), arama ve sık kullanılanlar.
// Durum: ~/.local/state/quickshell/.../launcher.json → { usage: { <id>: { count, last } }, sort: "az", pinned: [<id>] }
Singleton {
    id: apps

    readonly property string terminal: "kitty"

    // Menüde gösterilecek uygulamalar, ada göre (Türkçe) sıralı.
    readonly property var list: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name, "tr"))

    readonly property alias usage: adapter.usage

    // Tüm uygulamalar ızgarasının sıralaması (arama sonuçları her zaman eşleşme puanına göre).
    readonly property var sortModes: [
        { id: "az", label: "A–Z" },
        { id: "za", label: "Z–A" },
        { id: "frequent", label: "En çok" },
        { id: "recent", label: "Son" }
    ]
    readonly property string sort: adapter.sort
    function setSort(mode) {
        adapter.sort = mode
        file.writeAdapter()
    }

    // Sıralanmış tam liste. Hiç kullanılmamış uygulamalar "En çok"/"Son"da alfabetik olarak sona gelir.
    readonly property var sorted: {
        const l = list.slice()
        // QML'in JS motorunda sort kararlı değil: eşitlikte alfabetik sıra açıkça korunur.
        const byName = (a, b) => a.name.localeCompare(b.name, "tr")
        switch (sort) {
        case "za":
            return l.reverse()
        case "frequent":
            return l.sort((a, b) => score(b.id) - score(a.id) || (usage[b.id]?.count ?? 0) - (usage[a.id]?.count ?? 0) || byName(a, b))
        case "recent":
            return l.sort((a, b) => (usage[b.id]?.last ?? 0) - (usage[a.id]?.last ?? 0) || byName(a, b))
        default:
            return l
        }
    }

    // Aynı adı taşıyan birden fazla uygulama (ör. sistem ve Flatpak Chrome, Nautilus ve Nemo "Dosyalar").
    readonly property var duplicateNames: {
        const seen = {}, dup = {}
        for (const e of list) {
            if (seen[e.name])
                dup[e.name] = true
            seen[e.name] = true
        }
        return dup
    }

    // Satırın alt yazısı: açıklama; aynı adlı başka uygulama varsa ayırt edici (Flatpak ya da kimliğin son parçası).
    function subtitle(e) {
        if (!e)
            return ""
        const info = e.genericName || e.comment
        if (!duplicateNames[e.name])
            return info
        const source = e.execString.includes("flatpak run") ? "Flatpak" : e.id.split(".").pop().toLowerCase()
        return info ? info + " · " + source : source
    }

    // Sabitlenen uygulamalar, kullanıcının belirlediği sırayla (kaldırılmış uygulamalar atlanır).
    readonly property int maxPinned: 12
    readonly property var pinned: adapter.pinned
        .map(id => list.find(e => e.id === id))
        .filter(e => e !== undefined)

    function isPinned(entry) { return !!entry && adapter.pinned.includes(entry.id) }

    function togglePin(entry) {
        if (!entry)
            return
        const ids = adapter.pinned.slice()
        const i = ids.indexOf(entry.id)
        if (i >= 0)
            ids.splice(i, 1)
        else if (ids.length < maxPinned)
            ids.push(entry.id)
        else
            return
        adapter.pinned = ids
        file.writeAdapter()
    }

    // Sabitlenenler içinde bir adım sola (-1) ya da sağa (+1).
    function movePin(entry, delta) {
        const ids = adapter.pinned.slice()
        const i = ids.indexOf(entry.id), j = i + delta
        if (i < 0 || j < 0 || j >= ids.length)
            return
        ids.splice(j, 0, ids.splice(i, 1)[0])
        adapter.pinned = ids
        file.writeAdapter()
    }

    // Sürükle-bırak sonrası yeni sıra (kimlik listesi).
    function setPinnedOrder(ids) {
        adapter.pinned = ids.filter(id => adapter.pinned.includes(id))
        file.writeAdapter()
    }

    // Kullanım geçmişini sil (sık kullanılanlardan çıkar).
    function forget(entry) {
        if (!entry || !usage[entry.id])
            return
        const u = Object.assign({}, usage)
        delete u[entry.id]
        adapter.usage = u
        file.writeAdapter()
    }

    // Frecency'ye göre ilk 6; sabitlenenler zaten üstte olduğu için tekrar gösterilmez.
    readonly property var frequent: list
        .filter(e => score(e.id) > 0 && !adapter.pinned.includes(e.id))
        .sort((a, b) => score(b.id) - score(a.id) || a.name.localeCompare(b.name, "tr"))
        .slice(0, 6)

    // Sık kullanım puanı: kullanım sayısı × yakınlık ağırlığı.
    function score(id) {
        const u = usage[id]
        if (!u)
            return 0
        const days = (Date.now() - u.last) / 86400000
        const weight = days < 1 ? 4 : days < 7 ? 2 : days < 30 ? 1 : 0.5
        return u.count * weight
    }

    // Küçük harf + Türkçe karakter katlama: "Dosya Yöneticisi" ile "dosya yoneticisi" eşleşsin.
    function fold(s) {
        return (s ?? "").replace(/İ/g, "i").toLowerCase().replace(/\u0307/g, "")
            .replace(/ı/g, "i").replace(/ş/g, "s").replace(/ğ/g, "g")
            .replace(/ü/g, "u").replace(/ö/g, "o").replace(/ç/g, "c")
    }

    // Bulanık eşleşme: harfler sırayla geçiyorsa puan, geçmiyorsa 0. Kelime başında ve art arda eşleşen harfler
    // bonus alır: "gchr" → "Google CHRome" (30), "AppImaGe LauncHeR" (≈5) değil.
    function fuzzy(needle, hay) {
        let i = 0, bonus = 0, prev = -2
        for (let j = 0; j < hay.length && i < needle.length; j++) {
            if (hay[j] !== needle[i])
                continue
            if (j === 0 || /[\s\-_.]/.test(hay[j - 1]))
                bonus += 10
            else if (j === prev + 1)
                bonus += 5
            prev = j
            i++
        }
        return i === needle.length ? Math.min(190, 50 + bonus) : 0
    }

    // Kısaltma: sorgunun her harfi sırayla bir kelimenin baş harfi ("vsc" → Visual Studio Code).
    function acronym(needle, hay) {
        const initials = hay.split(/[\s\-_.]+/).filter(w => w !== "").map(w => w[0]).join("")
        return needle.length >= 2 && initials.startsWith(needle)
    }

    function matchScore(e, q) {
        const name = fold(e.name)
        if (name === q) return 1000
        if (name.startsWith(q)) return 800
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 600
        if (name.includes(q)) return 400
        if (acronym(q, name)) return 350
        const extra = fold([e.genericName, e.keywords.join(" "), e.comment].join(" "))
        if (extra.split(/[\s\-_.,;]+/).some(w => w.startsWith(q))) return 300
        if (extra.includes(q)) return 200
        return fuzzy(q, name)
    }

    function search(query) {
        const q = fold(query.trim())
        if (q === "")
            return sorted
        return list
            .map(e => ({ e: e, s: matchScore(e, q) }))
            .filter(r => r.s > 0)
            .sort((a, b) => b.s - a.s || score(b.e.id) - score(a.e.id) || a.e.name.localeCompare(b.e.name, "tr"))
            .map(r => r.e)
    }

    function launch(entry) {
        if (!entry)
            return
        const u = Object.assign({}, usage)
        const prev = u[entry.id]
        u[entry.id] = { count: (prev ? prev.count : 0) + 1, last: Date.now() }
        adapter.usage = u
        file.writeAdapter()

        if (entry.runInTerminal)
            Quickshell.execDetached([terminal, "-e", ...entry.command])
        else
            entry.execute()
    }

    // Mutlak yol, temadaki ikon ya da genel uygulama ikonu; hiçbiri yoksa "" (satır baş harfi gösterir).
    function iconSource(entry) {
        const icon = entry ? entry.icon : ""
        if (icon.startsWith("/"))
            return "file://" + icon
        if (icon !== "" && Quickshell.hasThemeIcon(icon))
            return Quickshell.iconPath(icon)
        return Quickshell.iconPath("application-x-executable", true)
    }

    FileView {
        id: file
        path: Quickshell.statePath("launcher.json")
        // İlk kullanıma kadar dosya yok; okuma uyarısı basılmasın.
        printErrors: false
        blockLoading: true

        JsonAdapter {
            id: adapter
            property var usage: ({})
            property string sort: "az"
            property var pinned: []
        }
    }
}
