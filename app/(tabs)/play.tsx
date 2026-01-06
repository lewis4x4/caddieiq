import { useState } from 'react';
import { View, Text, TextInput, FlatList, TouchableOpacity, ActivityIndicator } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { Search, MapPin, ChevronLeft } from 'lucide-react-native';
import { useRouter } from 'expo-router';
import { supabase } from '../../lib/supabase';

// Define the shape of search results based on our Edge Function
type CourseStub = {
    id: string; // external_course_id
    club_name: string;
    course_name: string;
    location: {
        city: string;
        state: string;
    };
};

export default function PlayScreen() {
    const [query, setQuery] = useState('');
    const [results, setResults] = useState<CourseStub[]>([]);
    const [loading, setLoading] = useState(false);
    const router = useRouter();

    const searchCourses = async () => {
        if (query.length < 3) return;
        setLoading(true);

        try {
            const { data, error } = await supabase.functions.invoke('course-search', {
                body: { query }
            });

            if (error) {
                console.error("Search error:", error);
            } else {
                // Map the result from the edge function
                setResults((data.courses || []).map((c: any) => ({
                    id: c.id,
                    club_name: c.club_name,
                    course_name: c.course_name,
                    location: c.location
                })));
            }
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    return (
        <View className="flex-1 bg-black pt-14 px-4">
            <StatusBar style="light" />

            <Text className="text-white text-3xl font-bold mb-6">Start Round</Text>

            {/* Search Bar */}
            <View className="flex-row items-center bg-zinc-900 rounded-xl px-4 py-3 border border-zinc-800 mb-6">
                <Search color="#71717a" size={20} />
                <TextInput
                    className="flex-1 text-white ml-3 text-lg font-medium"
                    placeholder="Search golf courses..."
                    placeholderTextColor="#71717a"
                    value={query}
                    onChangeText={setQuery}
                    onSubmitEditing={searchCourses}
                    returnKeyType="search"
                    autoFocus
                />
                {loading && <ActivityIndicator size="small" color="#22c55e" />}
            </View>

            {/* Results */}
            <FlatList
                data={results}
                keyExtractor={(item) => item.id}
                contentContainerStyle={{ gap: 12, paddingBottom: 40 }}
                ListEmptyComponent={
                    !loading && query.length > 2 ? (
                        <Text className="text-zinc-500 text-center mt-10">No courses found.</Text>
                    ) : null
                }
                renderItem={({ item }) => (
                    <TouchableOpacity
                        className="bg-zinc-900 p-4 rounded-xl border border-zinc-800 flex-row items-center justify-between active:bg-zinc-800"
                        onPress={() => console.log('Select course:', item.id)} // Will route to setup
                    >
                        <View>
                            <Text className="text-white font-bold text-lg">{item.club_name}</Text>
                            <Text className="text-zinc-400 font-medium">{item.course_name}</Text>
                            <View className="flex-row items-center mt-2">
                                <MapPin size={14} color="#71717a" />
                                <Text className="text-zinc-500 text-xs ml-1">
                                    {item.location?.city}, {item.location?.state}
                                </Text>
                            </View>
                        </View>
                    </TouchableOpacity>
                )}
            />
        </View>
    );
}
