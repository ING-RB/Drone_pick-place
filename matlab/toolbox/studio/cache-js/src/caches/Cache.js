/**
 * @copyright 2024 The MathWorks, Inc.
 */
class Cache {
    /**
     * @param {CacheService} service An instance of the cache service.
     * @param {String} key The key used to retrieve the value from the cache.
     * @param {Function} getterFn Function used to retrieve the value from the server.
     */
    constructor (service, key, getterFn) {
        this._service = service;
        this._key = key;
        this._getterFn = getterFn;
        this._value = undefined;
        this._ready = undefined;

        Object.seal(this);
    }

    /**
     * Promise is resolved once the cache has initialized.
     * @return {Promise}
     */
    get ready () {
        if (!this._ready) this._ready = this.init();

        return this._ready;
    }

    /**
     * Retrieves the value from the cache and stores it in memory.
     * @return {Promise<void>}
     */
    async init () {
        this._value = await this._getValue();

        // Cache was empty, try to get value from server.
        !this._value && await this.refresh();
    }

    /**
     * Retrieves the value from the server, caches it, and then stores it in memory.
     * @return {Promise<void>}
     */
    async refresh () {
        const value = await this._getterFn();
        await this._setValue(value);
        this._value = value;
    }

    /**
     * Get the cached value
     * @return {*}
     */
    get value () {
        return this._value;
    }

    /**
     * Get the cached value
     * @return {Promise<*>}
     * @private
     */
    async _getValue () {
        return this._service?.get(this._key);
    }

    /**
     * Set the cached value
     * @param {*} value
     * @return {Promise}
     * @private
     */
    async _setValue (value) {
        return this._service?.set(this._key, value);
    }
}

export default Cache;
