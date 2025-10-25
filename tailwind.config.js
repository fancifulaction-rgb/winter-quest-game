/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          100: '#DCE4FF',
          500: '#4A6CFD',
          700: '#3A59E3',
        },
        accent: {
          500: '#FBBF24',
          700: '#D97706',
        },
        neutral: {
          50: '#E8EAF6',
          200: '#A0A8C0',
          300: '#3B456D',
          800: '#141A3C',
          900: '#0A0F2C',
        },
        success: '#22C55E',
        warning: '#F59E0B',
        error: '#EF4444',
      },
      fontFamily: {
        'heading': ['Manrope', 'sans-serif'],
        'body': ['Inter', 'sans-serif'],
      },
      spacing: {
        'xs': '8px',
        'sm': '16px',
        'md': '24px',
        'lg': '32px',
        'xl': '48px',
        'xxl': '64px',
        'xxxl': '96px',
      },
      borderRadius: {
        'md': '12px',
        'sm': '8px',
        'full': '9999px',
      },
      boxShadow: {
        'md': '0 4px 12px rgba(74, 108, 253, 0.1)',
        'lg': '0 8px 24px rgba(74, 108, 253, 0.2)',
      },
      animation: {
        'fade-in': 'fadeIn 0.4s ease-out',
        'slide-up': 'slideUp 0.4s ease-out',
        'snow-fall': 'snowFall 10s linear infinite',
        'pulse-gold': 'pulseGold 2s ease-in-out infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        snowFall: {
          '0%': { transform: 'translateY(-100vh) translateX(0)' },
          '100%': { transform: 'translateY(100vh) translateX(100px)' },
        },
        pulseGold: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.7' },
        },
      },
    },
  },
  plugins: [],
}