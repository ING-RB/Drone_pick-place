/*global define */

define(
    "installer_login/PostMessageChannel", function () {
        "use strict";

        var Message, PostMessageChannel;

        Message = function (type, body) {
            this.type = type;
            this.body = body;
        };

        Message.serialize = function (type, body, tag) {
            var str = tag + JSON.stringify([type, body]);
            str = str.replace('"', '\"');
            return str;
        };

        Message.deserialize = function (data, tag) {

            var typeAndBody;
            if (data.indexOf(tag) !== 0) {
                return new Message();
            }

            typeAndBody = JSON.parse(data.replace(tag, ""));

            return new Message(typeAndBody[0], typeAndBody[1]);
        };

        Message.prototype.isValid = function () {
            return this.type && (this.body !== null);
        };

        Message.prototype.setEvent = function (event) {
            this.event = event;
        };

        /**
         * Lightweight cross-window communication over the postMessage API. Allows multiple window
         * objects to communicate (for example, a document containing an iframe can communicate
         * with the document in the iframe).
         */
        PostMessageChannel = function (localWindow, tag) {
            var self = this;

            this.tag = tag || "__mwpmc__";

            this.localWindow = localWindow;

            this.listeners = {};

            this.onMessage = function (event) {
                var message = Message.deserialize(event.data, self.tag);

                if (message.isValid() && self.hasListener(message.type)) {
                    message.setEvent(event);
                    self.listeners[message.type].call(self, message);
                }
            };

            this.addPostMessageListener();
        };

        /**
         * Clears the channel's event listeners. Also removes channel-related listeners from
         * the local window object.
         */
        PostMessageChannel.prototype.disconnect = function () {
            this.targetWindow = null;
            this.listeners = {};
            this.localWindow.removeEventListener("message", this.onMessage);
        };

        /**
         * Waits for another channel to send a connect message. On receiving this message,
         * the message sender is set as the channel's target.
         */
        PostMessageChannel.prototype.listen = function () {
            this.on("__connect", function (message) {
                this.setTargetWindow(message.event.source);
            });
        };

        /**
         * Sends a connect message to another window, and sets that window as the channel's target.
         */
        PostMessageChannel.prototype.connect = function (targetWindow) {
            this.setTargetWindow(targetWindow);

            this.send("__connect", this.localWindow.location.origin);
            this.send("connect", this.localWindow.location.origin);
        };

        /**
         * Adds a callback for a specified message type. Within the callback :this: is bound
         * to the channel object.
         */
        PostMessageChannel.prototype.on = function (type, listener) {
            this.listeners[type] = listener;
        };

        PostMessageChannel.prototype.hasListener = function (type) {
            return this.listeners[type] !== undefined;
        };

        /**
         * Sends a message to the channel's target window.
         */
        PostMessageChannel.prototype.send = function (type, body) {
            this.targetWindow.postMessage(Message.serialize(type, body || "", this.tag), "*");
        };

        PostMessageChannel.prototype.addPostMessageListener = function () {
            this.localWindow.addEventListener("message", this.onMessage, false);
        };

        PostMessageChannel.prototype.setTargetWindow = function (targetWindow) {
            this.targetWindow = targetWindow;
        };

        return PostMessageChannel;
    }
);