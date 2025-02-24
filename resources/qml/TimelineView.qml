// SPDX-FileCopyrightText: 2021 Nheko Contributors
//
// SPDX-License-Identifier: GPL-3.0-or-later

import "./delegates"
import "./device-verification"
import "./emoji"
import "./voip"
import Qt.labs.platform 1.1 as Platform
import QtGraphicalEffects 1.0
import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import im.nheko 1.0
import im.nheko.EmojiModel 1.0

Page {
    id: timelineRoot

    property var colors: currentActivePalette
    property var systemInactive
    property var inactiveColors: currentInactivePalette ? currentInactivePalette : systemInactive
    readonly property int avatarSize: 40
    property real highlightHue: colors.highlight.hslHue
    property real highlightSat: colors.highlight.hslSaturation
    property real highlightLight: colors.highlight.hslLightness

    palette: colors

    FontMetrics {
        id: fontMetrics
    }

    EmojiPicker {
        id: emojiPopup

        colors: palette
        model: TimelineManager.completerFor("allemoji", "")
    }

    Component {
        id: userProfileComponent

        UserProfile {
        }

    }

    Component {
        id: roomSettingsComponent

        RoomSettings {
        }

    }

    Component {
        id: mobileCallInviteDialog

        CallInvite {
        }

    }

    Component {
        id: quickSwitcherComponent

        QuickSwitcher {
        }

    }

    Component {
        id: forwardCompleterComponent

        ForwardCompleter {
        }

    }

    Shortcut {
        sequence: "Ctrl+K"
        onActivated: {
            var quickSwitch = quickSwitcherComponent.createObject(timelineRoot);
            TimelineManager.focusTimeline();
            quickSwitch.open();
        }
    }

    Platform.Menu {
        id: messageContextMenu

        property string eventId
        property string link
        property string text
        property int eventType
        property bool isEncrypted
        property bool isEditable
        property bool isSender

        function show(eventId_, eventType_, isSender_, isEncrypted_, isEditable_, link_, text_, showAt_) {
            eventId = eventId_;
            eventType = eventType_;
            isEncrypted = isEncrypted_;
            isEditable = isEditable_;
            isSender = isSender_;
            if (text_)
                text = text_;
            else
                text = "";
            if (link_)
                link = link_;
            else
                link = "";
            if (showAt_)
                open(showAt_);
            else
                open();
        }

        Platform.MenuItem {
            visible: messageContextMenu.text
            enabled: visible
            text: qsTr("Copy")
            onTriggered: Clipboard.text = messageContextMenu.text
        }

        Platform.MenuItem {
            visible: messageContextMenu.link
            enabled: visible
            text: qsTr("Copy link location")
            onTriggered: Clipboard.text = messageContextMenu.link
        }

        Platform.MenuItem {
            id: reactionOption

            visible: TimelineManager.timeline ? TimelineManager.timeline.permissions.canSend(MtxEvent.Reaction) : false
            text: qsTr("React")
            onTriggered: emojiPopup.show(null, function(emoji) {
                TimelineManager.queueReactionMessage(messageContextMenu.eventId, emoji);
            })
        }

        Platform.MenuItem {
            visible: TimelineManager.timeline ? TimelineManager.timeline.permissions.canSend(MtxEvent.TextMessage) : false
            text: qsTr("Reply")
            onTriggered: TimelineManager.timeline.replyAction(messageContextMenu.eventId)
        }

        Platform.MenuItem {
            visible: messageContextMenu.isEditable && (TimelineManager.timeline ? TimelineManager.timeline.permissions.canSend(MtxEvent.TextMessage) : false)
            enabled: visible
            text: qsTr("Edit")
            onTriggered: TimelineManager.timeline.editAction(messageContextMenu.eventId)
        }

        Platform.MenuItem {
            text: qsTr("Read receipts")
            onTriggered: TimelineManager.timeline.readReceiptsAction(messageContextMenu.eventId)
        }

        Platform.MenuItem {
            visible: messageContextMenu.eventType == MtxEvent.ImageMessage || messageContextMenu.eventType == MtxEvent.VideoMessage || messageContextMenu.eventType == MtxEvent.AudioMessage || messageContextMenu.eventType == MtxEvent.FileMessage || messageContextMenu.eventType == MtxEvent.Sticker || messageContextMenu.eventType == MtxEvent.TextMessage || messageContextMenu.eventType == MtxEvent.LocationMessage || messageContextMenu.eventType == MtxEvent.EmoteMessage || messageContextMenu.eventType == MtxEvent.NoticeMessage
            text: qsTr("Forward")
            onTriggered: {
                var forwardMess = forwardCompleterComponent.createObject(timelineRoot);
                forwardMess.setMessageEventId(messageContextMenu.eventId);
                forwardMess.open();
            }
        }

        Platform.MenuItem {
            text: qsTr("Mark as read")
        }

        Platform.MenuItem {
            text: qsTr("View raw message")
            onTriggered: TimelineManager.timeline.viewRawMessage(messageContextMenu.eventId)
        }

        Platform.MenuItem {
            // TODO(Nico): Fix this still being iterated over, when using keyboard to select options
            visible: messageContextMenu.isEncrypted
            enabled: visible
            text: qsTr("View decrypted raw message")
            onTriggered: TimelineManager.timeline.viewDecryptedRawMessage(messageContextMenu.eventId)
        }

        Platform.MenuItem {
            visible: (TimelineManager.timeline ? TimelineManager.timeline.permissions.canRedact() : false) || messageContextMenu.isSender
            text: qsTr("Remove message")
            onTriggered: TimelineManager.timeline.redactEvent(messageContextMenu.eventId)
        }

        Platform.MenuItem {
            visible: messageContextMenu.eventType == MtxEvent.ImageMessage || messageContextMenu.eventType == MtxEvent.VideoMessage || messageContextMenu.eventType == MtxEvent.AudioMessage || messageContextMenu.eventType == MtxEvent.FileMessage || messageContextMenu.eventType == MtxEvent.Sticker
            enabled: visible
            text: qsTr("Save as")
            onTriggered: TimelineManager.timeline.saveMedia(messageContextMenu.eventId)
        }

        Platform.MenuItem {
            visible: messageContextMenu.eventType == MtxEvent.ImageMessage || messageContextMenu.eventType == MtxEvent.VideoMessage || messageContextMenu.eventType == MtxEvent.AudioMessage || messageContextMenu.eventType == MtxEvent.FileMessage || messageContextMenu.eventType == MtxEvent.Sticker
            enabled: visible
            text: qsTr("Open in external program")
            onTriggered: TimelineManager.timeline.openMedia(messageContextMenu.eventId)
        }

        Platform.MenuItem {
            visible: messageContextMenu.eventId
            enabled: visible
            text: qsTr("Copy link to event")
            onTriggered: TimelineManager.timeline.copyLinkToEvent(messageContextMenu.eventId)
        }

    }

    Rectangle {
        anchors.fill: parent
        color: colors.window

        Component {
            id: deviceVerificationDialog

            DeviceVerification {
            }

        }

        Connections {
            target: TimelineManager
            onNewDeviceVerificationRequest: {
                var dialog = deviceVerificationDialog.createObject(timelineRoot, {
                    "flow": flow
                });
                dialog.show();
            }
            onOpenProfile: {
                var userProfile = userProfileComponent.createObject(timelineRoot, {
                    "profile": profile
                });
                userProfile.show();
            }
        }

        Connections {
            target: TimelineManager.timeline
            onOpenRoomSettingsDialog: {
                var roomSettings = roomSettingsComponent.createObject(timelineRoot, {
                    "roomSettings": settings
                });
                roomSettings.show();
            }
        }

        Connections {
            target: CallManager
            onNewInviteState: {
                if (CallManager.haveCallInvite && Settings.mobileMode) {
                    var dialog = mobileCallInviteDialog.createObject(msgView);
                    dialog.open();
                }
            }
        }

        Label {
            visible: !TimelineManager.timeline && !TimelineManager.isInitialSync
            anchors.centerIn: parent
            text: qsTr("No room open")
            font.pointSize: 24
            color: colors.text
        }

        BusyIndicator {
            visible: running
            anchors.centerIn: parent
            running: TimelineManager.isInitialSync
            height: 200
            width: 200
            z: 3
        }

        ColumnLayout {
            id: timelineLayout

            visible: TimelineManager.timeline != null
            anchors.fill: parent
            spacing: 0

            TopBar {
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                z: 3
                color: colors.mid
            }

            Rectangle {
                id: msgView

                Layout.fillWidth: true
                Layout.fillHeight: true
                color: colors.base

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    StackLayout {
                        id: stackLayout

                        currentIndex: 0

                        Connections {
                            function onActiveTimelineChanged() {
                                stackLayout.currentIndex = 0;
                            }

                            target: TimelineManager
                        }

                        MessageView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        Loader {
                            source: CallManager.isOnCall && CallManager.callType != CallType.VOICE ? "voip/VideoCall.qml" : ""
                            onLoaded: TimelineManager.setVideoCallItem()
                        }

                    }

                    TypingIndicator {
                    }

                }

            }

            CallInviteBar {
                id: callInviteBar

                Layout.fillWidth: true
                z: 3
            }

            ActiveCallBar {
                Layout.fillWidth: true
                z: 3
            }

            Rectangle {
                Layout.fillWidth: true
                z: 3
                height: 1
                color: colors.mid
            }

            ReplyPopup {
            }

            MessageInput {
            }

        }

        NhekoDropArea {
            anchors.fill: parent
            roomid: TimelineManager.timeline ? TimelineManager.timeline.roomId() : ""
        }

    }

    PrivacyScreen {
        anchors.fill: parent
        visible: Settings.privacyScreen
        screenTimeout: Settings.privacyScreenTimeout
        timelineRoot: timelineLayout
    }

    systemInactive: SystemPalette {
        colorGroup: SystemPalette.Disabled
    }

}
