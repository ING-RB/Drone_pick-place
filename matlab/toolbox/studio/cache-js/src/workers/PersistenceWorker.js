/**
 * @copyright Copyright 2024 The MathWorks, Inc.
 */
import init from './BaseWorker.js';
import PersistenceDatabase from '../db/PersistenceDatabase.js';

init(new PersistenceDatabase());
