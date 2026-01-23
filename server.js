const express = require('express');
const path = require('path');
const app = express();
const PORT = 3001;

// 1. Serve Static Assets (CSS, JS, Images)
// This ensures your styles and scripts still work even with clean URLs
app.use('/css', express.static(path.join(__dirname, 'css')));
app.use('/js', express.static(path.join(__dirname, 'js')));
app.use('/images', express.static(path.join(__dirname, 'images')));
app.use('/html', express.static(path.join(__dirname, 'html')));

// 2. DEFINE CLEAN URL ROUTES
// This maps "Clean Name" -> "Actual File"

// Root URL (localhost:3001) -> Shows Loader
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'html', 'loader.html'));
});

// Home URL (localhost:3001/home) -> Shows Homepage
app.get('/homepage', (req, res) => {
    res.sendFile(path.join(__dirname, 'html', 'homepage.html'));
});

app.get('/register-option', (req, res) => {
    res.sendFile(path.join(__dirname, 'html', 'register-option.html'));
});

// Register URL (localhost:3001/register) -> Shows Register
app.get('/register', (req, res) => {
    res.sendFile(path.join(__dirname, 'html', 'register.html'));
});

// Sign In URL (localhost:3001/signin) -> Shows Sign In
app.get('/signin', (req, res) => {
    res.sendFile(path.join(__dirname, 'html', 'signin.html'));
});

// Dashboard URL (localhost:3001/dashboard) -> Shows Dashboard
app.get('/dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, 'html', 'user-dashboard.html'));
});

// 3. Start the Server
app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
});