/**
 * @copyright Copyright 2024 The MathWorks, Inc.
 */
import isNumber from '../utilities/isNumber.js';
import isString from '../utilities/isString.js';
import wrapRequestWithPromise from '../utilities/wrapRequestWithPromise.js';

/* eslint-disable-next-line no-undef */
const worker = self;

const { indexedDB } = worker;

export default class Database {
    /**
     * Constructor for Database class
     * @param {String} name Name of the database
     * @param {Number} [version=1] Version of the database schema
     * @throws {Error} If name is not a string
     * @throws {Error} If version is not a number
     */
    constructor (name, version = 1) {
        if (!isString(name)) throw new Error('Parameter "name" must be a string.');
        if (!isNumber(version)) throw new Error('Parameter "version" must be a number.');

        this._name = name;
        this._version = version;
        this._db = undefined;
        this._request = undefined;
        this._ready = undefined;
    }

    /**
     * Creates a database connection
     * @param {Function} [onUpgradeNeeded]
     * @return {Promise<Boolean>}
     */
    async connect (onUpgradeNeeded) {
        if (this._ready) return this._ready;

        this._ready = new Promise((resolve, reject) => {
            this._request = indexedDB.open(this._name, this._version);

            this._request.onsuccess = e => {
                this._db = e.target.result;
                resolve(true);
            };

            this._request.onerror = e => reject(e.message);

            onUpgradeNeeded && (this._request.onupgradeneeded = onUpgradeNeeded);
        });

        return this._ready;
    }

    /**
     * Closes the database connection
     * @return {Promise<Boolean>}
     */
    async close () {
        this._db.close();
        this._ready = undefined;
        return true;
    }

    /**
     * Creates an object store in the database.
     * @param {String} name The name of the object store.
     * @param {Object} options Options for the object store.
     * @return {Promise<IDBObjectStore>}
     */
    async createObjectStore (name, options) {
        if (this._db.objectStoreNames.contains(name)) throw new Error(`Object store named "${name}" already exists.`);

        return this._db.createObjectStore(name, options);
    }

    /**
     * Deletes an object store from the database.
     * @param {String} name The name of the object store to delete.
     * @return {Promise<void>}
     */
    async deleteObjectStore (name) {
        if (!this._db.objectStoreNames.contains(name)) throw new Error(`Object store named "${name}" does not exist.`);

        this._db.deleteObjectStore(name);
    }

    /**
     * Get a value from the database
     * @param {String} name The name of the object store
     * @param {String} key The key to fetch
     * @return {Promise<*>}
     */
    async get (name, key) {
        if (!isString(name)) throw new Error('Parameter "name" must be a string.');
        if (!isString(key)) throw new Error('Parameter "key" must be a string.');

        return wrapRequestWithPromise(() => this._db
            .transaction([name], 'readonly')
            .objectStore(name)
            .get(key)
        );
    }

    /**
     * Set a value in the database
     * @param {String} name The name of the object store
     * @param {*} value The value to set
     * @return {Promise}
     */
    async set (name, value) {
        if (!isString(name)) throw new Error('Parameter "name" must be a string.');

        return wrapRequestWithPromise(() => this._db
            .transaction([name], 'readwrite')
            .objectStore(name)
            .put(value)
        );
    }

    /**
     * Delete a value from the database
     * @param {String} name The name of the object store
     * @param {String} key The key to delete
     * @return {Promise}
     */
    async delete (name, key) {
        if (!isString(name)) throw new Error('Parameter "name" must be a string.');
        if (!isString(key)) throw new Error('Parameter "key" must be a string.');

        return wrapRequestWithPromise(() => this._db
            .transaction([name], 'readwrite')
            .objectStore(name)
            .delete(key)
        );
    }

    /**
     * Clears all values from the database in the specified store.
     * @param {String} name The name of the object store.
     * @param {String|String[]} [query] The query to filter values.
     * @return {Promise}
     */
    async getAll (name, query) {
        return wrapRequestWithPromise(() => this._db
            .transaction([name], 'readonly')
            .objectStore(name)
            .getAll(query)
        );
    }

    /**
     * Clears all values from the database in the specified store.
     * @param {String} name The name of the object store.
     * @return {Promise}
     */
    async clear (name) {
        return wrapRequestWithPromise(() => this._db
            .transaction([name], 'readwrite')
            .objectStore(name)
            .clear()
        );
    }

    /**
     * Deletes the database.
     * @return {Promise<Boolean|String>}
     */
    async deleteDatabase () {
        return new Promise((resolve, reject) => {
            const request = indexedDB.deleteDatabase(this._name);
            request.onerror = e => reject(e.message);
            request.onsuccess = e => resolve(true);
        });
    }

    /**
     * Checks if the database request is done
     * @return {Boolean} True if the request readyState is 'done', false otherwise
     */
    get isDone () {
        return this._request?.readyState === 'done';
    }
}
