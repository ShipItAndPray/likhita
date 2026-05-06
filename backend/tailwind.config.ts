import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./lib/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        rama: {
          brand: "#8B0000",
          accent: "#D4AF37",
          surface: "#FFF8DC",
          surfaceAlt: "#F5E6C8",
          ink: "#E34234",
          textPrimary: "#2C1810",
          textSecondary: "#6B4423",
        },
        ram: {
          brand: "#FF7722",
          accent: "#D4AF37",
          surface: "#F5E6D3",
          surfaceAlt: "#EDD9B8",
          ink: "#1C1C1C",
          textPrimary: "#2C1810",
          textSecondary: "#5C4033",
        },
      },
      fontFamily: {
        display: ["var(--font-display)", "serif"],
        body: ["var(--font-body)", "sans-serif"],
      },
    },
  },
  plugins: [],
};

export default config;
