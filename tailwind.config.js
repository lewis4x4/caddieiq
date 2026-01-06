/** @type {import('tailwindcss').Config} */
module.exports = {
  // NOTE: Update this to include the paths to all of your component files.
  content: ["./app/**/*.{js,jsx,ts,tsx}", "./components/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        // Golf-specific palette
        golf: {
          light: '#4ade80', // green-400
          DEFAULT: '#22c55e', // green-500
          dark: '#16a34a', // green-600
        },
      },
      fontFamily: {
        // We will add fonts later, keeping default for now
      }
    },
  },
  plugins: [],
}
