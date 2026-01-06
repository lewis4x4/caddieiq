import { supabase } from "./supabase";
import { getDB } from "./sqlite";
import { useSyncStore } from "../stores/syncQueueStore";
import NetInfo from "@react-native-community/netinfo";

export const processSyncQueue = async () => {
    const { setSyncing, setPendingCount, isOnline } = useSyncStore.getState();

    // Quick check for network
    const netState = await NetInfo.fetch();
    if (!netState.isConnected) return;

    if (isOnline === false) return; // Store says we are offline (maybe manual toggle)

    setSyncing(true);
    const db = await getDB();

    try {
        // Fetch pending items
        const pendingItems: any[] = await db.getAllAsync(
            `SELECT * FROM sync_queue WHERE status = 'pending' ORDER BY created_at ASC`
        );

        setPendingCount(pendingItems.length);

        if (pendingItems.length === 0) {
            setSyncing(false);
            return;
        }

        for (const item of pendingItems) {
            try {
                const payload = JSON.parse(item.payload);

                // Execute against Supabase based on action
                let error = null;

                const table = item.entity_type; // e.g. 'rounds', 'hole_scores'

                if (item.action === 'create') {
                    const { error: insertError } = await supabase.from(table).insert(payload);
                    error = insertError;
                } else if (item.action === 'update') {
                    const { error: updateError } = await supabase.from(table).update(payload).eq('id', item.entity_id);
                    error = updateError;
                } else if (item.action === 'delete') {
                    const { error: deleteError } = await supabase.from(table).delete().eq('id', item.entity_id);
                    error = deleteError;
                }

                if (error) throw error;

                // Success - remove from queue
                await db.runAsync(`DELETE FROM sync_queue WHERE id = ?`, [item.id]);

            } catch (err) {
                console.error("Sync failed for item", item.id, err);
                // Mark as failed or increment retry (simple fail for now)
                await db.runAsync(`UPDATE sync_queue SET status = 'failed', retry_count = retry_count + 1 WHERE id = ?`, [item.id]);
            }
        }

        // Re-check count
        const remaining: any[] = await db.getAllAsync(`SELECT count(*) as count FROM sync_queue WHERE status = 'pending'`);
        setPendingCount(remaining[0].count);

    } catch (e) {
        console.error("Sync process error:", e);
    } finally {
        setSyncing(false);
    }
};
