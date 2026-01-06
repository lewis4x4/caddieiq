import React, { useState } from "react";
import { View, Text, TextInput, Alert, ActivityIndicator } from "react-native";
import { Button } from "../../components/ui/Button";
import { supabase } from "../../lib/supabase";
import { useRouter } from "expo-router";
import { StatusBar } from "expo-status-bar";

export default function Login() {
    const [email, setEmail] = useState("");
    const [loading, setLoading] = useState(false);
    const router = useRouter();

    async function signInWithEmail() {
        setLoading(true);
        const { error } = await supabase.auth.signInWithOtp({
            email,
            options: {
                shouldCreateUser: true, // Auto-signup
            }
        });

        if (error) {
            Alert.alert("Error", error.message);
        } else {
            Alert.alert("Check your inbox", "We sent you a login link!");
        }
        setLoading(false);
    }

    return (
        <View className="flex-1 bg-zinc-900 justify-center px-8">
            <StatusBar style="light" />

            <View className="mb-10 items-center">
                <View className="h-20 w-20 bg-golf rounded-full items-center justify-center mb-6 shadow-lg shadow-golf/20">
                    <Text className="text-4xl">⛳</Text>
                </View>
                <Text className="text-3xl font-bold text-white text-center">
                    Welcome to CaddieIQ
                </Text>
                <Text className="text-zinc-400 mt-2 text-center">
                    Enter your email to sign in or create an account
                </Text>
            </View>

            <View className="space-y-4">
                <View>
                    <Text className="text-zinc-300 mb-2 font-medium">Email Address</Text>
                    <TextInput
                        className="bg-zinc-800 border border-zinc-700 text-white p-4 rounded-xl text-lg font-medium"
                        placeholder="golfer@example.com"
                        placeholderTextColor="#71717a"
                        autoCapitalize="none"
                        keyboardType="email-address"
                        value={email}
                        onChangeText={setEmail}
                    />
                </View>

                <Button
                    onPress={signInWithEmail}
                    disabled={loading || !email}
                    className="w-full mt-4"
                    size="lg"
                >
                    {loading ? <ActivityIndicator color="white" /> : "Send Magic Link"}
                </Button>
            </View>

            <Text className="text-zinc-500 text-center mt-8 text-sm">
                By continuing, you agree to our Terms & Privacy Policy.
            </Text>
        </View>
    );
}
