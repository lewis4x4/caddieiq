import * as SQLite from 'expo-sqlite';
import { Platform } from 'react-native';

let db: any = null;

const createMockWebDB = () => ({
  execAsync: async () => { },
  runAsync: async () => ({ changes: 0, lastInsertRowId: 0 }),
  getAllAsync: async () => [],
  getFirstAsync: async () => null,
  getEachAsync: async () => { },
});

export const getDB = async () => {
  if (db) return db;

  if (Platform.OS === 'web') {
    db = createMockWebDB();
    console.log("⚠️ Running in WEB mode: SQLite is mocked (no persistence).");
    return db;
  }

  db = await SQLite.openDatabaseAsync('caddieiq.db');
  await initDB(db);
  return db;
};

const initDB = async (database: SQLite.SQLiteDatabase) => {
  if (Platform.OS === 'web') return;

  // Create tables for offline data
  await database.execAsync(`
    PRAGMA journal_mode = WAL;
    
    -- Sync Queue
    CREATE TABLE IF NOT EXISTS sync_queue (
      id TEXT PRIMARY KEY NOT NULL,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      action TEXT NOT NULL, -- create, update, delete
      payload TEXT, -- JSON string
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      status TEXT DEFAULT 'pending', -- pending, syncing, failed
      retry_count INTEGER DEFAULT 0
    );

    -- Course Cache
    CREATE TABLE IF NOT EXISTS cached_courses (
      id TEXT PRIMARY KEY NOT NULL,
      external_id TEXT UNIQUE NOT NULL,
      data TEXT NOT NULL, -- JSON string of full course data including tees/holes
      last_updated TEXT DEFAULT CURRENT_TIMESTAMP
    );

    -- Active Round (Snapshot)
    CREATE TABLE IF NOT EXISTS local_rounds (
      id TEXT PRIMARY KEY NOT NULL,
      status TEXT DEFAULT 'in_progress', -- in_progress, completed
      data TEXT NOT NULL, -- JSON string of round data
      synced BOOLEAN DEFAULT 0,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    );
  `);
};

// Helper for UUID generation if needed locally
export const generateUUID = () => {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
};
