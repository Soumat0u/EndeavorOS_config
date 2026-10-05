import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"
import ".."

// Bir ekranın masaüstü katmanı: saat. Her ekranda bir tane açılır; her widget yalnızca
// kayıtlı olduğu ekranda görünür (services/WidgetLayout.qml). Katman ekranı kaplar ve pencerelerin arkasında durur;
// yalnızca widget'ların üstü tıklanabilir, geri kalan alan masaüstüne geçer.
PanelWindow {
    id: window

    required property ShellScreen modelData
    // Ekran çıkarılırken katman yok edilmeden önce modelData bir an boş kalır.
    readonly property string monitor: modelData?.name ?? ""

    // Sağ tık menüsü açıkken bütün katman tıklamayı alır, dışarı tıklayınca menü kapanabilsin.
    property bool menuOpen: false

    screen: modelData
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    // Başka ekrandan bir widget sürüklenirken bu ekranın katmanı tamamıyla girdi alır. İmlecin altında hiç yüzey yokken
    // (boş masaüstü) Hyprland, tuş basılı olsa bile imleç ekrana geçince sürüklemeyi kesiyor; tam ekran bir yüzey bunu önler.
    readonly property bool dragFromElsewhere: WidgetLayout.drag !== null && WidgetLayout.drag.monitor !== monitor
    mask: menuOpen || dragFromElsewhere ? fullMask : widgetMask

    WlrLayershell.namespace: "desktop-widgets"
    // Başka ekrandan bir widget sürüklenirken bu ekranın katmanı pencerelerin üstüne çıkar ki widget'ın buraya
    // taşan kısmı görünsün. (Sürüklemenin başladığı ekranın katmanı yerinde kalır, yoksa sürükleme kopar.)
    WlrLayershell.layer: dragFromElsewhere ? WlrLayer.Overlay : WlrLayer.Bottom
    // Tıklanınca klavye odağını alabilsin: Hyprland, fare tuşu basılıyken imleci ilk yüzeye yalnızca klavye odağında bir
    // yüzey varsa bağlı tutuyor. İki ekran da boşken (odak hiçbir yerde değilken) bu olmazsa sürükleme ekran sınırında kopuyor.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property Region fullMask: Region { item: stage }
    property Region widgetMask: Region {
        Region { item: clock.visible ? clock : null }
    }

    Item {
        id: stage
        anchors.fill: parent

        Draggable {
            id: clock
            key: "clock"
            desktop: window
            defaultX: (stage.width - width) / 2
            defaultY: 70

            ClockFace {}
        }
    }
}
