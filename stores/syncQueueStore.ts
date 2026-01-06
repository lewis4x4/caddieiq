import { create } from 'zustand';

interface SyncState {
    isOnline: boolean;
    isSyncing: boolean;
    pendingCount: number;
    setOnlineStatus: (status: boolean) => void;
    setSyncing: (status: boolean) => void;
    setPendingCount: (count: number) => void;
}

export const useSyncStore = create<SyncState>((set) => ({
    isOnline: true,
    isSyncing: false,
    pendingCount: 0,
    setOnlineStatus: (status) => set({ isOnline: status }),
    setSyncing: (status) => set({ isSyncing: status }),
    setPendingCount: (count) => set({ pendingCount: count }),
}));
