/**
 * Controller base class for Hardware Manager web modules
 * Copyright 2021-2024 The MathWorks, Inc.
 */
'use strict';
define([
    './ClientMessageHandler'
], function (
    MessageHandler
) {
    return class Controller {
        constructor (_clientId) {
            this._clientId = _clientId || null;
            this.messageHandler = new MessageHandler(this.getStaticChannel(), _clientId) || null;

            // Add subscriptions to receive message from MATLAB
            this.addServerSubscriptions();
        }

        // Start - Implementations required on the clients //
        // Returns a web object
        getView () {
            // NO OP
        }

        getStaticChannel () {
            // NO OP
        }

        addServerSubscriptions () {
            // NO OP
        }

        // End - Implementations required on the clients //

        publish (action, params) {
            this.messageHandler.publish(action, params);
        }

        subscribe (actionName, callbackName) {
            this.messageHandler.subscribe(actionName, this[callbackName || actionName].bind(this));
        }
    };
});
