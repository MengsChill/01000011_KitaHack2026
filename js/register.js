// js/register.js

// ==========================================
// 1. WAVE ANIMATION LOGIC (Restored)
// ==========================================
const canvas = document.getElementById('wave-canvas');

if (canvas) {
    const ctx = canvas.getContext('2d');
    let width, height, increment = 0;

    function resize() { 
        width = window.innerWidth; 
        height = window.innerHeight; 
        canvas.width = width; 
        canvas.height = height; 
    }
    window.addEventListener('resize', resize);
    resize();

    function animate() {
        // Clear screen
        ctx.fillStyle = "#ffffff"; 
        ctx.fillRect(0, 0, width, height);

        // Define waves
        const waves = [
            { y: height * 0.5, length: 0.01, amplitude: 80, speed: 0.01, color: "rgba(37, 99, 235, 0.1)" },
            { y: height * 0.5, length: 0.02, amplitude: 60, speed: 0.02, color: "rgba(6, 182, 212, 0.15)" },
            { y: height * 0.5, length: 0.03, amplitude: 40, speed: 0.04, color: "rgba(37, 99, 235, 0.05)" }
        ];

        // Draw waves
        waves.forEach((wave) => {
            ctx.beginPath(); 
            ctx.moveTo(0, wave.y);
            for (let i = 0; i < width; i++) {
                ctx.lineTo(i, wave.y + Math.sin(i * wave.length + increment * wave.speed * 100) * wave.amplitude);
            }
            ctx.lineTo(width, height); 
            ctx.lineTo(0, height);
            ctx.fillStyle = wave.color; 
            ctx.fill();
        });

        increment += 0.01;
        requestAnimationFrame(animate);
    }
    animate();
}

// ==========================================
// 2. FIREBASE IMPORTS (CDN Style)
// ==========================================
import { createUserWithEmailAndPassword } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js";
import { auth } from "./firebase-config.js"; 


// ==========================================
// 3. PASSWORD VALIDATION & UI LOGIC
// ==========================================
const passwordInput = document.getElementById('password-input');
const confirmInput = document.getElementById('confirm-password-input');
const submitBtn = document.getElementById('submit-btn');
const matchMessage = document.getElementById('match-message');

// Requirements Configuration
const reqs = {
    length: { regex: /^.{8,10}$/, el: document.getElementById('req-length') },
    upper: { regex: /[A-Z]/, el: document.getElementById('req-upper') },
    special: { regex: /[!@#$%^&*(),.?":{}|<>]/, el: document.getElementById('req-special') },
    mix: { regex: /^(?=.*[0-9])(?=.*[a-zA-Z])/, el: document.getElementById('req-mix') }
};

function validatePassword() {
    const val = passwordInput.value;
    let allValid = true;

    // A. Check Requirements
    for (const key in reqs) {
        if (reqs[key].el) { // Only check if element exists
            const isValid = reqs[key].regex.test(val);
            const item = reqs[key].el;
            
            if (isValid) {
                item.classList.add('valid');
            } else {
                item.classList.remove('valid');
                allValid = false;
            }
        }
    }

    // B. Check Match
    let match = false;
    if (confirmInput) {
        match = (val === confirmInput.value && val !== "");
        if(matchMessage) {
            if(match) {
                matchMessage.textContent = "Passwords match!";
                matchMessage.style.color = "#2ecc71";
            } else {
                matchMessage.textContent = "Passwords do not match";
                matchMessage.style.color = "red";
            }
        }
    }

    // C. Enable/Disable Button
    if (submitBtn) {
        if (allValid && match) {
            submitBtn.disabled = false;
            submitBtn.style.opacity = "1";
            submitBtn.style.cursor = "pointer";
        } else {
            submitBtn.disabled = true;
            submitBtn.style.opacity = "0.5";
            submitBtn.style.cursor = "not-allowed";
        }
    }
}

// Add Input Listeners
if(passwordInput) passwordInput.addEventListener('input', validatePassword);
if(confirmInput) confirmInput.addEventListener('input', validatePassword);

// Toggle Eye Icon Logic
document.querySelectorAll('.toggle-password').forEach(icon => {
    icon.addEventListener('click', function() {
        this.classList.toggle('fa-eye');
        this.classList.toggle('fa-eye-slash');
        const input = this.previousElementSibling;
        if (input) {
            input.type = (input.type === 'password') ? 'text' : 'password';
        }
    });
});


// ==========================================
// 4. REGISTRATION SUBMISSION
// ==========================================
const registerForm = document.getElementById('register-form');

if (registerForm) {
    registerForm.addEventListener('submit', (e) => {
        e.preventDefault();
        
        const email = document.getElementById('email-input').value; 
        const password = passwordInput.value;

        // Visual Feedback (Button Loading State)
        if(submitBtn) submitBtn.innerText = "Creating...";

        createUserWithEmailAndPassword(auth, email, password)
            .then((userCredential) => {
                console.log("User Registered:", userCredential.user);
                alert("Account Created Successfully!");
                window.location.href = "homepage.html"; // Redirect to Homepage
            })
            .catch((error) => {
                console.error("Error:", error.message);
                alert("Error: " + error.message);
                if(submitBtn) submitBtn.innerText = "CREATE ACCOUNT"; // Reset button text
            });
    });
}