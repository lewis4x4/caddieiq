import { useEffect } from 'react';
import NetInfo from '@react-native-community/netinfo';
import { useSyncStore } from '../stores/syncQueueStore';
import { processSyncQueue } from '../lib/sync';
import { getDB } from '../lib/sqlite';

export function useOfflineSync() {
    const { setOnlineStatus, setPendingCount, isOnline, pendingCount, isSyncing } = useSyncStore();

    useEffect(() => {
        // Initial Load of pending count
        const loadPending = async () => {
            try {
                const db = await getDB();
                const res: any[] = await db.getAllAsync(`SELECT count(*) as count FROM sync_queue WHERE status = 'pending'`);
                setPendingCount(res[0].count);
            } catch (e) {
                console.error("Failed to load pending count", e);
            }
        };
        loadPending();

        // Network Listener
        const unsubscribe = NetInfo.addEventListener((state) => {
            const online = !!state.isConnected && !!state.isInternetReachable;
            setOnlineStatus(online);

            if (online) {
                // Trigger sync when coming online
                processSyncQueue();
            }
        });

        return () => unsubscribe();
    }, []);

    return {
        isOnline,
        isSyncing,
        pendingCount,
        syncNow: processSyncQueue
    };
}
