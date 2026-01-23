// js/auth.js

// 1. Import the specific Firebase Auth functions we need
import { GoogleAuthProvider, signInWithPopup } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js";

// 2. Import the 'auth' object we created in Step 2
import { auth } from "./firebase-config.js";

// 3. Define the function to handle Google Sign In
export function signInWithGoogle() {
    const provider = new GoogleAuthProvider();

    // This command opens the Google popup window
    signInWithPopup(auth, provider)
        .then((result) => {
            // SUCCESS: The user is logged in
            const user = result.user;
            console.log("User signed in successfully:", user.displayName);

            // Optional: Save user info to local storage so other pages can see it
            localStorage.setItem('user', JSON.stringify(user));

            // REDIRECT: Send them to the dashboard
            // Make sure this file path is correct for your folder structure
            window.location.href = "user-dashboard.html"; 
        })
        .catch((error) => {
            // ERROR: Something went wrong
            console.error("Error during sign in:", error.message);
            alert("Login Failed: " + error.message);
        });
}