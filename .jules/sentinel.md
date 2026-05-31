# 🛡️ Sentinel Security Journal

## 2025-05-14 - Email Enumeration via Proactive Checks
**Vulnerability:** The application performed real-time checks to see if an email existed in the database as the user typed, and provided specific error messages during login differentiating between "email not found" and "incorrect password".
**Learning:** UX-friendly features like "auto-switching to signup" or "real-time availability checks" can inadvertently leak user existence, which is a privacy risk and aids brute-force attacks.
**Prevention:** Use unified error messages for authentication (e.g., "Invalid email or password"). Avoid real-time existence checks on public forms.
