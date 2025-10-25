/**
 * @copyright Copyright 2024 The MathWorks, Inc.
 */
import { CLEAR, CLOSE, CONNECT, DELETE, DELETE_DATABASE, GET, GET_ALL, SET } from '../constants/main.js';

/**
 * @type {Window | (WorkerGlobalScope & Window)}
 */
/* eslint-disable-next-line no-undef */
const scope = self;

/**
 * @param {CacheDatabase | PersistenceDatabase} db
 */
const init = db => {
    /**
     * A map of operations keyed by operation name to execute against the cache database.
     * @type {Map<String, function(key:String, value:*): Promise<*>>}
     */
    const operations = new Map([
        [CLEAR, () => db.clear()],
        [CLOSE, () => db.close()],
        [CONNECT, () => db.connect()],
        [DELETE, key => db.delete(key)],
        [GET, key => db.get(key)],
        [GET_ALL, query => db.getAll(query)],
        [SET, (key, value) => db.set(key, value)],
        [DELETE_DATABASE, () => db.deleteDatabase()]
    ]);

    /**
     * Handler for messages received by the web worker.
     * @param {MessageEvent} e The message event containing data from main thread.
     * @param {{id: String, name: String, key: String, value: *}} e.data The data object containing operation details.
     */
    scope.onmessage = async e => {
        const { id, name, key, value, query } = e.data ?? {};

        if (!operations.has(name)) throw new Error(`Operation "${name}" not found.`);

        const operation = operations.get(name);
        const detail = await operation(key ?? query, value);

        scope.postMessage({ id, name, detail });
    };
};

export default init;
