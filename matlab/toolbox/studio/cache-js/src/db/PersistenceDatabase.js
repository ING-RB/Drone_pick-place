/**
 * @copyright Copyright 2024 The MathWorks, Inc.
 */
import Database from './Database.js';
import isString from '../utilities/isString.js';

import {
    PERSISTENCE_DB_NAME,
    PERSISTENCE_DB_STORE_NAME,
    PERSISTENCE_DB_VERSION,
    PERSISTENCE_DB_KEY_PATH
} from '../constants/main.js';

export default class PersistenceDatabase {
    constructor () {
        this._db = new Database(PERSISTENCE_DB_NAME, PERSISTENCE_DB_VERSION);
    }

    /**
     * Called when the database needs to be upgraded.
     * @param {MessageEvent} e
     * @private
     */
    _onUpgradeNeeded (e) {
        // Version 1
        const db = e.target.result;
        const store = db.createObjectStore(PERSISTENCE_DB_STORE_NAME, { keyPath: PERSISTENCE_DB_KEY_PATH });
        store.createIndex(PERSISTENCE_DB_KEY_PATH, [PERSISTENCE_DB_KEY_PATH], { unique: true });
    }

    /**
     * Creates a database connection
     * @return {Promise<Boolean>} Resolves when connection is opened
     */
    async connect () {
        return this._db.connect(this._onUpgradeNeeded);
    }

    /**
     * Get a value from the database
     * @param {String} key The key to fetch
     * @return {Promise<*>} Resolves with the value or undefined if not found
     */
    async get (key) {
        await this.connect();
        return this._db.get(PERSISTENCE_DB_STORE_NAME, key);
    }

    /**
     * Set a value in the database
     * @param {String} key The key to set
     * @param {*} value The value to set
     * @return {Promise} Resolves when value is set
     */
    async set (key, value) {
        if (!isString(key)) throw new Error('Parameter "key" must be a string.');

        await this.connect();
        return this._db.set(PERSISTENCE_DB_STORE_NAME, { key, value });
    }

    /**
     * Delete a value from the database
     * @param {String} key The key to delete
     * @return {Promise}
     */
    async delete (key) {
        await this.connect();
        return this._db.delete(PERSISTENCE_DB_STORE_NAME, key);
    }

    /**
     * Clears all values from the database in the specified store.
     * @param {String} [query] The query to filter values.
     * @return {Promise}
     */
    async getAll (query) {
        await this.connect();
        return await this._db.getAll(PERSISTENCE_DB_STORE_NAME, query) ?? [];
    }

    /**
     * Clears all values from the database in the specified store.
     * @return {Promise}
     */
    async clear () {
        await this.connect();
        return this._db.clear(PERSISTENCE_DB_STORE_NAME);
    }

    /**
     * Closes the database connection
     * @return {Promise} Resolves when connection is closed
     */
    async close () {
        await this.connect();
        return this._db.close();
    }

    /**
     * Deletes the database.
     * @return {Promise<Boolean|String>}
     */
    async deleteDatabase () {
        return this._db.deleteDatabase();
    }

    /**
     * Checks if the database request is done
     * @return {Boolean}
     */
    get isDone () {
        return this._db.isDone;
    }
}
