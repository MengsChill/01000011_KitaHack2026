// 1. Keep these https imports (DO NOT change these to the ones in your screenshot)
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js";

// 2. This is the config from your screenshot
const firebaseConfig = {
  apiKey: "AIzaSyDrR9FVYwkoJWxITztniUSTwOgRORk6kB0",
  authDomain: "smartstick2026-6a6ce.firebaseapp.com",
  projectId: "smartstick2026-6a6ce",
  storageBucket: "smartstick2026-6a6ce.firebasestorage.app",
  messagingSenderId: "786434805872",
  appId: "1:786434805872:web:9f26550cce0550e06064b5",
  measurementId: "G-YGY8EX4EJE"
};

// 3. Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

export { auth };