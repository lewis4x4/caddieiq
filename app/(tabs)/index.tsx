import { View, Text, ScrollView, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { useAuth } from '../../hooks/useAuth';
import { StatusBar } from 'expo-status-bar';
import { PlusCircle, Trophy, TrendingDown, Activity } from 'lucide-react-native';

export default function HomeScreen() {
    const { profile, signOut } = useAuth();
    const router = useRouter();

    return (
        <View className="flex-1 bg-black">
            <StatusBar style="light" />
            <ScrollView className="flex-1 px-4 pt-14">
                {/* Header */}
                <View className="flex-row justify-between items-center mb-8">
                    <View>
                        <Text className="text-zinc-400 text-sm font-medium">Welcome back,</Text>
                        <Text className="text-white text-2xl font-bold">
                            {profile?.display_name || profile?.email?.split('@')[0] || 'Golfer'}
                        </Text>
                    </View>
                    <TouchableOpacity
                        onPress={signOut}
                        className="h-10 w-10 bg-zinc-800 rounded-full items-center justify-center border border-zinc-700"
                    >
                        <Text className="text-lg">👤</Text>
                    </TouchableOpacity>
                </View>

                {/* Quick Action: Start Round */}
                <TouchableOpacity
                    onPress={() => router.push("/(tabs)/play")}
                    className="bg-golf rounded-2xl p-6 mb-8 flex-row items-center justify-between shadow-lg shadow-golf/20 active:opacity-90"
                >
                    <View>
                        <Text className="text-zinc-900 text-xl font-bold">Start Round</Text>
                        <Text className="text-zinc-800 font-medium">Find a course and tee off</Text>
                    </View>
                    <PlusCircle color="#18181b" size={32} strokeWidth={2.5} />
                </TouchableOpacity>

                {/* Stats Preview Grid */}
                <View className="flex-row gap-4 mb-4">
                    <View className="flex-1 bg-zinc-900 p-4 rounded-xl border border-zinc-800">
                        <View className="bg-zinc-800 self-start p-2 rounded-lg mb-2">
                            <Trophy size={20} color="#fbbf24" />
                        </View>
                        <Text className="text-zinc-400 text-xs font-bold uppercase tracking-wider mb-1">Handicap</Text>
                        <Text className="text-white text-2xl font-bold">--</Text>
                    </View>
                    <View className="flex-1 bg-zinc-900 p-4 rounded-xl border border-zinc-800">
                        <View className="bg-zinc-800 self-start p-2 rounded-lg mb-2">
                            <TrendingDown size={20} color="#22c55e" />
                        </View>
                        <Text className="text-zinc-400 text-xs font-bold uppercase tracking-wider mb-1">Last 5 Avg</Text>
                        <Text className="text-white text-2xl font-bold">--</Text>
                    </View>
                </View>

                {/* Recent Activity Stub */}
                <View className="mt-6">
                    <View className="flex-row items-center gap-2 mb-4">
                        <Activity size={20} color="#22c55e" />
                        <Text className="text-white text-lg font-bold">Recent Rounds</Text>
                    </View>

                    <View className="bg-zinc-900 rounded-xl p-8 items-center border border-zinc-800 border-dashed">
                        <Text className="text-zinc-500 text-center">No rounds played yet.</Text>
                        <TouchableOpacity
                            onPress={() => router.push("/(tabs)/play")}
                            className="mt-4 bg-zinc-800 px-4 py-2 rounded-full"
                        >
                            <Text className="text-white font-medium">Log your first round</Text>
                        </TouchableOpacity>
                    </View>
                </View>
            </ScrollView>
        </View>
    );
}
