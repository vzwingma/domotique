/**
 * Setup des variables d'environnement pour les tests Jest.
 * Ce fichier est chargé avant chaque fichier de test (setupFiles).
 * Les variables doivent être définies AVANT le require('../app') pour que
 * la validation d'environnement dans app.js ne déclenche pas process.exit(1).
 */
'use strict';

process.env.MAC                          = 'AA:BB:CC:DD:EE:FF';
process.env.PASSWD                       = 'testpassword';
process.env.AUTHAPI                      = 'testuser';
process.env.PASSWDAPI                    = 'testpass';
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
