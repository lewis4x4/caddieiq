import { View, Text } from "react-native";
import { StatusBar } from "expo-status-bar";

export default function Home() {
    return (
        <View className="flex-1 items-center justify-center bg-zinc-900">
            <StatusBar style="light" />
            <View className="p-6 bg-zinc-800 rounded-2xl border border-zinc-700 w-11/12 max-w-sm items-center shadow-xl shadow-black/50">
                <View className="h-16 w-16 bg-golf rounded-full items-center justify-center mb-6 shadow-lg shadow-golf/20">
                    <Text className="text-3xl">⛳</Text>
                </View>
                <Text className="text-3xl font-bold text-white mb-2">CaddieIQ</Text>
                <Text className="text-zinc-400 text-center mb-8">
                    Your personal AI caddie. Offline-first, premium insights.
                </Text>

                <View className="w-full space-y-4">
                    <View className="bg-zinc-700/50 p-4 rounded-xl border border-zinc-600">
                        <Text className="text-golf font-semibold text-center">NativeWind v4 Active</Text>
                    </View>
                </View>
            </View>
        </View>
    );
}
