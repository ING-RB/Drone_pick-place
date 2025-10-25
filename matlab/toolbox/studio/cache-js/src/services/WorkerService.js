/**
 * @copyright Copyright 2024 The MathWorks, Inc.
 */
import bindFunctions from 'studio-core-js/utilities/bindFunctions.js';
import getUUID from 'studio-core-js/utilities/getUUID.js';
import Remote from 'mw-remote/Remote.js';

import {
    CLEAR,
    CLOSE,
    CONNECT,
    DELETE,
    DELETE_DATABASE,
    GET,
    GET_ALL,
    SET
} from '../constants/main.js';

const { Map, Worker } = window;
const messageMap = new Map();

class WorkerService {
    constructor (workerUrl) {
        /**
         * @type {Worker}
         * @private
         */
        const url = new URL(Remote.createWorkerRoutingHostUrl(workerUrl));
        this._worker = new Worker(url.pathname, { type: 'module' });
        this._worker.onerror = this._onError;
        this._worker.onmessage = this._onMessage;

        bindFunctions(this);

        Object.seal(this);
    }

    /**
     * Send a message to the web worker.
     * @param {String} name The name of the method to call.
     * @param {String} [key] The key for get/set methods.
     * @param {*} [value] The value for set methods.
     * @returns {Promise} A promise that resolves when a response is received.
     * @private
     */
    async _send (name, key, value) {
        const id = getUUID();
        const message = { id, name };
        key && (message.key = key);
        value && (message.value = value);

        this._worker.postMessage(message);

        return new Promise(resolve => messageMap.set(id, resolve));
    }

    /**
     * Logs an error to the console.
     * @param {MessageEvent} e
     * @private
     */
    _onError (e) {
        console.error('WorkerService error', e);
    }

    /**
     * Resolves a promise from the message map when a response is received.
     * @param {MessageEvent} e
     * @private
     */
    _onMessage (e) {
        const { id, detail = {} } = e.data;
        const value = detail.value ?? detail;
        const resolve = messageMap.get(id);
        resolve(value);
    }

    /**
     * Creates a connection
     * @return {Promise<Boolean>} Resolves when connection is opened
     */
    async connect () {
        return this._send(CONNECT);
    }

    /**
     * Get a value from the cache
     * @param {String} key The key to fetch
     * @return {Promise<*>} Resolves with the value or undefined if not found
     */
    async get (key) {
        return this._send(GET, key);
    }

    /**
     * Set a value in the cache
     * @param {String} key The key to set
     * @param {*} value The value to set
     * @return {Promise} Resolves when value is set
     */
    async set (key, value) {
        return this._send(SET, key, value);
    }

    /**
     * Delete a value from the cache
     * @param {String} key The key to delete
     * @return {Promise}
     */
    async delete (key) {
        return this._send(DELETE, key);
    }

    /**
     * Clears all values from the database in the specified store.
     * @param {String} [query] The query to filter values.
     * @return {Promise}
     */
    async getAll (query) {
        return await this._send(GET_ALL, query) ?? [];
    }

    /**
     * Clears all values from the database in the specified store.
     * @return {Promise}
     */
    async clear () {
        return this._send(CLEAR);
    }

    /**
     * Closes the connection
     * @return {Promise} Resolves when connection is closed
     */
    async close () {
        return this._send(CLOSE);
    }

    /**
     * Deletes the database.
     * @return {Promise<Boolean|String>}
     */
    async deleteDatabase () {
        return this._send(DELETE_DATABASE);
    }
}

export default WorkerService;
