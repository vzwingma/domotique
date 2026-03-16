'use strict';

module.exports = {
    testEnvironment: 'node',
    setupFiles: ['./tests/setup.js'],
    // Le mock tydom-client ne se propage pas aux workers Jest isolés, et les
    // open handles (morgan-body, listeners SIGINT/SIGTERM) font bloquer Jest
    // indéfiniment en mode multi-workers. On désactive les workers via le
    // flag --runInBand passé dans le script npm test.
};
