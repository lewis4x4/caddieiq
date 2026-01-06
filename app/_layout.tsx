import "../global.css";
import { Slot, useRouter, useSegments } from "expo-router";
import { View, ActivityIndicator } from "react-native";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { useEffect } from "react";
import { useAuth } from "../hooks/useAuth";

function InitialLayout() {
    const { session, loading } = useAuth();
    const segments = useSegments();
    const router = useRouter();

    useEffect(() => {
        if (loading) return;

        // TEMPORARY: Bypass Auth check for development
        // const inAuthGroup = segments[0] === "(auth)";
        // if (!session && !inAuthGroup) {
        //   router.replace("/(auth)/login");
        // } else if (session && inAuthGroup) {
        //   router.replace("/");
        // }
    }, [session, loading, segments]);

    if (loading) {
        return (
            <View className="flex-1 justify-center items-center bg-zinc-900">
                <ActivityIndicator size="large" color="#22c55e" />
            </View>
        );
    }

    return (
        <View className="flex-1 bg-black">
            <Slot />
        </View>
    );
}

export default function Layout() {
    return (
        <SafeAreaProvider>
            <InitialLayout />
        </SafeAreaProvider>
    );
}
