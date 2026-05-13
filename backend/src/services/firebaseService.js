'use strict';

const admin = require('firebase-admin');
const { getSetting, invalidate } = require('./settingsService');

let initializedForProject = null;
let initPromise = null;

/**
 * Lazy-initialise (or re-initialise) the Firebase Admin app with the
 * service account that an operator pasted into the admin panel. Each call
 * checks whether the stored project ID still matches what's already booted
 * and rebuilds the app if not.
 */
async function getAdminAppOrNull() {
  if (initPromise) return initPromise;

  initPromise = (async () => {
    const cfg = await getSetting('auth.firebase');
    if (!cfg || !cfg.enabled || !cfg.projectId || !cfg.serviceAccountJson) {
      initializedForProject = null;
      return null;
    }

    let serviceAccount;
    try {
      serviceAccount = typeof cfg.serviceAccountJson === 'string'
        ? JSON.parse(cfg.serviceAccountJson)
        : cfg.serviceAccountJson;
    } catch (err) {
      console.error('firebase: bad service account JSON', err);
      initializedForProject = null;
      return null;
    }

    const projectId = cfg.projectId || serviceAccount.project_id;
    if (initializedForProject === projectId) {
      return admin.app();
    }

    // Tear down any previous app so we can swap credentials.
    for (const app of admin.apps) {
      try { await app.delete(); } catch (_) { /* noop */ }
    }

    const app = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId,
    });
    initializedForProject = projectId;
    return app;
  })();

  try {
    return await initPromise;
  } finally {
    initPromise = null;
  }
}

async function verifyIdToken(idToken) {
  const app = await getAdminAppOrNull();
  if (!app) {
    const err = new Error('firebase_not_configured');
    err.code = 'firebase_not_configured';
    throw err;
  }
  return app.auth().verifyIdToken(idToken, true);
}

/** Returns the *public* Firebase web config the mobile app needs to init the SDK. */
async function getPublicConfig() {
  const cfg = (await getSetting('auth.firebase')) || {};
  return {
    enabled: !!(cfg.enabled && cfg.apiKey && cfg.projectId && cfg.appId),
    apiKey: cfg.apiKey || '',
    appId: cfg.appId || '',
    projectId: cfg.projectId || '',
    messagingSenderId: cfg.messagingSenderId || '',
    iosAppId: cfg.iosAppId || '',
    iosBundleId: cfg.iosBundleId || '',
    androidPackageName: cfg.androidPackageName || 'com.vacado.app',
  };
}

function invalidateFirebase() {
  invalidate('auth.firebase');
  initializedForProject = null;
  for (const app of admin.apps) {
    try { app.delete(); } catch (_) { /* noop */ }
  }
}

module.exports = { verifyIdToken, getPublicConfig, invalidateFirebase };
