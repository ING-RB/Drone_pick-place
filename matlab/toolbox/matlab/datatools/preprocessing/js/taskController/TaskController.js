/*
    Copyright 2023 The MathWorks, Inc.
*/

define('preprocessing/taskController/TaskController', [
    'mw-messageservice/MessageService',
    'mw-data-model/On',
    'inspector_peer/InspectorFactory',
    'inspector_client/widget/InspectorWidget',
    'mw-form/CheckBox',
    'mw-form/PushButton',
    'dojo/i18n!preprocessing/l10n/nls/TaskController'
], function (MessageService, On, InspectorFactory, Inspector, CheckBox, PushButton, taskControllerl10n) {
    'use strict';

    const CLIENT_MESSAGE_TYPES = {
        TASK_ACCEPTED: 5,
        TASK_CANCELLED: 6,
        AUTORUN_CHANGED: 7,
        RENDER_FIGURES: 10
    };

    const SERVER_MESSAGE_TYPES = {
        VISIBILITY_CHANGED: 2,
        SRV_MESSAGE_SET_APPLY_BTN_STATE: 3,
        SRV_MESSAGE_SET_CANCEL_BTN_STATE: 4
    };

    class TaskController {
        constructor (channel, propertyInspectorChannel) {
            this._on = new On();
            this._inspectorManager = null;
            this._channel = channel;
            this._propertyInspectorChannel = propertyInspectorChannel;
            this._buttonGroup = null;
            this.visibilityChangedCallback = null;
            this.taskCompletedCallback = null;

            MessageService.subscribe(this._channel, this._martialServerMessage, this);

            this._inspectorManager = InspectorFactory.createInspector({
                messageService: MessageService.messageService,
                application: Inspector.DEFAULT_INSPECTOR_APPLICATION,
                channel: this._propertyInspectorChannel,
                editable: true,
                cssSpecifier: 'mw_type_Inspector',
                ignoreUpdates: false,
                requestFocusOnStart: true,
                dataTagRoot: 'mw.datatools.inspector',
                createDefaultClipboardService: false
            });

            return this;
        }

        _martialServerMessage (msg) {
            const types = SERVER_MESSAGE_TYPES;
            switch (msg.data.type) {
                case types.VISIBILITY_CHANGED:
                    this._setVisibility(msg.data.visibility);
                    break;
                case types.SRV_MESSAGE_SET_APPLY_BTN_STATE: {
                    const isDisabled = !msg.data.state; // Server sends whether button is enabled
                    this._setAcceptButtonState(isDisabled);
                    break;
                }
                case types.SRV_MESSAGE_SET_CANCEL_BTN_STATE: {
                    const isDisabled = !msg.data.state; // Server sends whether button is enabled
                    this._setCancelButtonState(isDisabled);
                    break;
                }
                default:
                    throw new Error(`History panel received message type value of ${msg.data.type}; no function exists to handle it`);
            }
        }

        _sendMessage (eventType, data) {
            const message = { eventType, data };
            MessageService.publish(this._channel, message);
        }

        /**
         * Creates all the elements for the button group. This is separated from
         * "_getButtonGroup()" for simpler testing.
         * @returns All button group elements
         */
        _createButtonGroupElements () {
            const autoPreviewCheckbox = new CheckBox({
                text: taskControllerl10n.PreviewCheckbox,
                checked: true
            });
            autoPreviewCheckbox.domNode.classList.add('controlElement');

            // Preview changes button
            const previewIcon = {
                id: 'playControl',
                height: 16,
                width: 16
            };
            const previewButton = new PushButton({ icon: previewIcon });
            previewButton.domNode.classList.add('controlElement');
            previewButton.domNode.classList.add('previewButton');
            previewButton.domNode.style.visibility = 'hidden';

            const banner = document.createElement('p');
            banner.innerText = taskControllerl10n.ReminderBannerText;
            banner.classList.add('controlElement', 'banner');

            const cancelButton = new PushButton({ text: taskControllerl10n.Cancel });
            cancelButton.domNode.classList.add('controlElement');
            cancelButton.domNode.classList.add('cancelButton');
            const acceptButton = new PushButton({ text: taskControllerl10n.Accept });
            acceptButton.domNode.classList.add('controlElement');
            acceptButton.domNode.classList.add('acceptButton');

            return {
                autoPreviewCheckbox,
                previewButton,
                banner,
                cancelButton,
                acceptButton
            };
        }

        /**
         * Creates the TaskController button group. This contains elements such as the
         * "Accept" and "Cancel" buttons for the current task.
         * @returns The button group.
         */
        _getButtonGroup () {
            // Create all the necessary elements...
            const elements = this._createButtonGroupElements();

            const buttonGroupDiv = document.createElement('div');
            buttonGroupDiv.classList.add('pa_taskPanel_buttonGroup');

            // ...add all the button group elements to the same parent div...
            elements.autoPreviewCheckbox.placeAt(buttonGroupDiv);
            elements.autoPreviewCheckbox.startup();
            buttonGroupDiv.appendChild(elements.previewButton.domNode);
            buttonGroupDiv.appendChild(elements.banner);
            buttonGroupDiv.appendChild(elements.cancelButton.domNode);
            buttonGroupDiv.appendChild(elements.acceptButton.domNode);

            buttonGroupDiv.setPreviewButtonVisibility = visibility => {
                elements.previewButton.domNode.style.visibility = visibility;
            };

            // ...and add callbacks to each interactive element.
            elements.autoPreviewCheckbox.on('change', evt => {
                // Toggle the preview button depending on whether this is checked.
                const checked = evt.mwEventData.newValue;
                const visibility = checked ? 'hidden' : 'visible';
                buttonGroupDiv.setPreviewButtonVisibility(visibility);

                this._sendMessage(CLIENT_MESSAGE_TYPES.AUTORUN_CHANGED, { checked });
            });

            elements.previewButton.on('click', () => {
                this._sendMessage(CLIENT_MESSAGE_TYPES.RENDER_FIGURES, {});
            });
            elements.acceptButton.on('click', () => {
                if (this.taskCompletedCallback) this.taskCompletedCallback('accept');
            });
            elements.cancelButton.on('click', () => {
                if (this.taskCompletedCallback) this.taskCompletedCallback('cancel');
            });

            // We add element references to the button group element so we may easily
            // refer to the elements in other functions & in tests.
            buttonGroupDiv.autoPreviewCheckbox = elements.autoPreviewCheckbox;
            buttonGroupDiv.previewButton = elements.previewButton;
            buttonGroupDiv.banner = elements.banner;
            buttonGroupDiv.cancelButton = elements.cancelButton;
            buttonGroupDiv.acceptButton = elements.acceptButton;

            return buttonGroupDiv;
        }

        sendAcceptButtonMessage () {
            this._sendMessage(CLIENT_MESSAGE_TYPES.TASK_ACCEPTED, {});
        }

        sendCancelButtonMessage () {
            this._sendMessage(CLIENT_MESSAGE_TYPES.TASK_CANCELLED, {});
        }

        getPanelContent () {
            const panelContentDiv = document.createElement('div');
            panelContentDiv.classList.add('pa_taskPanel');

            // Add the inspector to its own div so we can leverage flex display.
            const inspectorManagerDiv = document.createElement('div');
            inspectorManagerDiv.classList.add('pa_taskPanel_inspector');
            // Somehow, the Inspector Manager doesn't take up the full width by default;
            // it's likely due to its flex parent. Force its width to 100%.
            this._inspectorManager.domNode.style.width = '100%';
            inspectorManagerDiv.appendChild(this._inspectorManager.domNode);

            this._buttonGroup = this._getButtonGroup();

            panelContentDiv.appendChild(inspectorManagerDiv);
            panelContentDiv.appendChild(this._buttonGroup);

            // Hide the buttons by default. They will be shown when the server sends an
            // initialize message.
            this._buttonGroup.style.visibility = 'hidden';

            return panelContentDiv;
        }

        _setVisibility (isVisible) {
            const visibility = isVisible ? 'visible' : 'hidden';
            this._inspectorManager.domNode.style.visibility = visibility;
            this._buttonGroup.style.visibility = visibility;

            // g3188660: Prevent the preview checkbox from being displayed while the
            // button group is hidden.
            // Without doing this, after the user unchecks the automatic preview checkbox,
            // the preview checkbox will remain visible even when the button group becomes hidden.
            const showPreviewButton = !this._buttonGroup.autoPreviewCheckbox.checked && isVisible;
            if (showPreviewButton) this._buttonGroup.setPreviewButtonVisibility('visible');
            else this._buttonGroup.setPreviewButtonVisibility('hidden');

            if (this.visibilityChangedCallback) {
                this.visibilityChangedCallback(isVisible);
            }
        }

        _setAcceptButtonState (isDisabled) {
            this._buttonGroup.acceptButton.set('disabled', isDisabled);
        }

        _setCancelButtonState (isDisabled) {
            this._buttonGroup.cancelButton.set('disabled', isDisabled);
        }

        on (eventName, callback) {
            return this._on.on(eventName, callback);
        }

        destroy () {
            MessageService.unsubscribe(this._channel, '_martialServerMessage', this);
        }
    }

    return TaskController;
});
