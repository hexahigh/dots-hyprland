import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "chineseWord"

    readonly property string wordFontFamily: Config.options.background.widgets.chineseWord.fontFamily

    implicitHeight: wordCard.implicitHeight
    implicitWidth: wordCard.implicitWidth

    StyledDropShadow {
        target: wordCard
    }

    Rectangle {
        id: wordCard
        color: Appearance.colors.colPrimaryContainer
        radius: Appearance.rounding.large
        implicitWidth: maxTextWidth + padding * 2
        implicitHeight: contentColumn.implicitHeight + padding * 2

        property int padding: 16
        property int maxTextWidth: 280

        Column {
            id: contentColumn
            anchors.centerIn: parent
            spacing: 6
            width: wordCard.maxTextWidth

            StyledText {
                text: DailyChineseWord.data.chinese.length > 0 ? DailyChineseWord.data.chinese : Translation.tr("Loading...")
                color: Appearance.colors.colOnPrimaryContainer
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                width: parent.width
                font {
                    family: wordFontFamily.length > 0 ? wordFontFamily : Appearance.font.family.reading
                    pixelSize: 30
                    weight: Font.DemiBold
                }
            }

            StyledText {
                text: DailyChineseWord.data.pinyin
                color: Appearance.colors.colOnPrimaryContainer
                opacity: text.length > 0 ? 0.7 : 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                width: parent.width
                font {
                    family: wordFontFamily.length > 0 ? wordFontFamily : Appearance.font.family.reading
                    pixelSize: 18
                    weight: Font.Medium
                }
            }

            StyledText {
                text: DailyChineseWord.data.english
                color: Appearance.colors.colOnPrimaryContainer
                opacity: text.length > 0 ? 0.8 : 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                width: parent.width
                font {
                    family: wordFontFamily.length > 0 ? wordFontFamily : Appearance.font.family.reading
                    pixelSize: 16
                    weight: Font.Normal
                }
            }
        }
    }
}
