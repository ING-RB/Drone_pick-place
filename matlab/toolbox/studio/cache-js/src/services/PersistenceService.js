/**
 * @copyright Copyright 2024 The MathWorks, Inc.
 */
import WorkerService from './WorkerService.js';
import { PERSISTENCE_WORKER_URL } from '../constants/main.js';

class PersistenceService extends WorkerService {
    constructor () {
        super(PERSISTENCE_WORKER_URL);
    }
}

export default PersistenceService;
