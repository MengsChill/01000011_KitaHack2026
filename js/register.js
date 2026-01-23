const canvas = document.getElementById('wave-canvas');
const ctx = canvas.getContext('2d');
let width, height, increment = 0;

function resize() { 
    width = window.innerWidth; height = window.innerHeight; 
    canvas.width = width; canvas.height = height; 
}
window.addEventListener('resize', resize);
resize();

function animate() {
    ctx.fillStyle = "#ffffff"; ctx.fillRect(0, 0, width, height);
    const waves = [
        { y: height * 0.5, length: 0.01, amplitude: 80, speed: 0.01, color: "rgba(37, 99, 235, 0.1)" },
        { y: height * 0.5, length: 0.02, amplitude: 60, speed: 0.02, color: "rgba(6, 182, 212, 0.15)" },
        { y: height * 0.5, length: 0.03, amplitude: 40, speed: 0.04, color: "rgba(37, 99, 235, 0.05)" }
    ];
    waves.forEach((wave) => {
        ctx.beginPath(); ctx.moveTo(0, wave.y);
        for (let i = 0; i < width; i++) {
            ctx.lineTo(i, wave.y + Math.sin(i * wave.length + increment * wave.speed * 100) * wave.amplitude);
        }
        ctx.lineTo(width, height); ctx.lineTo(0, height);
        ctx.fillStyle = wave.color; ctx.fill();
    });
    increment += 0.01;
    requestAnimationFrame(animate);
}
animate();

// 1. USE THE EXACT SAME CDN LINK AS CONFIG
import { createUserWithEmailAndPassword } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js";

// 2. IMPORT THE AUTH OBJECT
import { auth } from "./firebase-config.js"; 

// 3. Your Register Logic
const registerForm = document.getElementById('register-form');

if (registerForm) {
    registerForm.addEventListener('submit', (e) => {
        e.preventDefault();
        
        const email = document.getElementById('email-input').value; 
        const password = document.getElementById('password-input').value;

        console.log("Attempting to register:", email); 

        createUserWithEmailAndPassword(auth, email, password)
            .then((userCredential) => {
                console.log("User Registered:", userCredential.user);
                alert("Registration Successful!");
                window.location.href = "signin.html";
            })
            .catch((error) => {
                console.error("Registration Failed:", error.code, error.message);
                alert("Error: " + error.message);
            });
    });
}