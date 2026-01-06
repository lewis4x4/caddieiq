import { Tabs } from 'expo-router';
import { LucideIcon, Home, Flag, User, PlusCircle } from 'lucide-react-native';

const TabIcon = ({ icon: Icon, color, size, focused }: { icon: LucideIcon; color: string; size: number; focused: boolean }) => {
    return <Icon color={color} size={size} strokeWidth={focused ? 3 : 2} />;
};

export default function TabLayout() {
    return (
        <Tabs
            screenOptions={{
                headerShown: false,
                tabBarStyle: {
                    backgroundColor: '#18181b', // zinc-900
                    borderTopColor: '#27272a', // zinc-800
                },
                tabBarActiveTintColor: '#22c55e', // green-500
                tabBarInactiveTintColor: '#71717a', // zinc-500
            }}
        >
            <Tabs.Screen
                name="index"
                options={{
                    title: "Home",
                    tabBarIcon: ({ color, size, focused }) => (
                        <TabIcon icon={Home} color={color} size={size} focused={focused} />
                    ),
                }}
            />
            <Tabs.Screen
                name="play"
                options={{
                    title: "Play",
                    tabBarIcon: ({ color, size, focused }) => (
                        <TabIcon icon={PlusCircle} color={color} size={size} focused={focused} />
                    ),
                }}
            />
            <Tabs.Screen
                name="rounds"
                options={{
                    title: "Rounds",
                    tabBarIcon: ({ color, size, focused }) => (
                        <TabIcon icon={Flag} color={color} size={size} focused={focused} />
                    ),
                }}
            />
            <Tabs.Screen
                name="profile"
                options={{
                    title: "Profile",
                    tabBarIcon: ({ color, size, focused }) => (
                        <TabIcon icon={User} color={color} size={size} focused={focused} />
                    ),
                }}
            />
        </Tabs>
    );
}
