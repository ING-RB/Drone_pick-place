/**
 * @copyright Copyright 2024 The MathWorks, Inc.
 */
import WorkerService from './WorkerService.js';
import { CACHE_WORKER_URL } from '../constants/main.js';

class CacheService extends WorkerService {
    constructor () {
        super(CACHE_WORKER_URL);
    }
}

export default CacheService;
