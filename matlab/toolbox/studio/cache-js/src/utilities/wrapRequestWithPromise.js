/**
 * @copyright Copyright 2024 The MathWorks, Inc.
 *
 * Wraps a request in a promise
 * @param {function():IDBRequest} requester The request function
 * @return {Promise<*>}
 */
export default requester => new Promise((resolve, reject) => {
    /**
     * @type {IDBRequest}
     */
    const request = requester();

    /**
     * @param {MessageEvent} e
     */
    request.onsuccess = e => resolve(e.target.result);

    /**
     * @param {ErrorEvent} e
     */
    request.onerror = e => reject(e.message);
});
