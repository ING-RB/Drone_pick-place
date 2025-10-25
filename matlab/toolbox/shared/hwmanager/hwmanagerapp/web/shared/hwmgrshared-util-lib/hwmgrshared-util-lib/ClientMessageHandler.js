/**
 * This handles the connector communication with a server (MATLAB) using
 * matlab.hwmgr.internal.MessageHandler.
 * Copyright 2021-2024 The MathWorks, Inc.
 */
'use strict';
define([
    'mw-messageservice/MessageService'
], function (MessageService) {
    return class ClientMessageHandler {
        constructor (_staticChannel, _clientId) {
            this.staticChannel = _staticChannel;
            this.clientId = _clientId === undefined ? this._getQueryVariable('clientid') : _clientId;
            this.channel = this.staticChannel + '/' + this.clientId;
            this.subscriptions = new Map();

            if (this._hostedInAppContainer()) {
                this.start();
            } else {
                this._connectedHandle = MessageService.on('connected', () => { this.start(); });
                MessageService.start();
            }
        }

        start () {
            if (!this._hostedInAppContainer()) {
                this._connectedHandle.remove();
            }
            MessageService.subscribe(this.channel, this.callbackHandler, this);
            this.publish('PubSubReady');
        }

        publish (_action, _data) {
            if (_data === undefined) {
                _data = {};
            }
            const message = { action: _action, params: _data };
            MessageService.publish(this.channel, message);
        }

        subscribe (action, callback) {
            this.subscriptions.set(action, callback);
        }

        unsubscribe (action) {
            if (this.subscriptions.has(action)) {
                this.subscriptions.delete(action);
            }
        }

        _getQueryVariable (variable) {
            const query = window.location.search.substring(1);
            const vars = query.split('&');
            for (let i = 0; i < vars.length; i++) {
                const pair = vars[i].split('=');
                if (decodeURIComponent(pair[0]) === variable) {
                    return decodeURIComponent(pair[1]);
                }
            }
            return '';
        }

        _hostedInAppContainer () {
            return window.location.href.includes('appcontainer');
        }

        /*******************************************************
         * @param {Object} eventData
         * @brief eventData object is passed to by MessageService api
         * eventData object always has 'data' property that contains
         * the payload of the message. The 'data' property is created by the
         * MessageService module. The paylod has to have the
         * following format:
         * eventData.data = { action: <action>
         *                    params: {
         *                        <
         *                            properties/values provided by server
         *                        >
         *                    }
         *                  }
         * valid 'action' property from the server
         * any other value will be discarded
         */
        callbackHandler (eventData) {
            const message = eventData.data;
            if (message.hasOwnProperty('action') && message.hasOwnProperty('params')) {
                const action = message.action;
                if (this.subscriptions.has(action)) {
                    this.subscriptions.get(action)(message.params);
                } else {
                    console.error(`${action} is not a registered action!`);
                }
            }
        }
    };
});
