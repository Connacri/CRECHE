# 🛡️ Sentinel Security Journal

## 2025-05-14 - Email Enumeration via Proactive Checks
**Vulnerability:** The application performed real-time checks to see if an email existed in the database as the user typed, and provided specific error messages during login differentiating between "email not found" and "incorrect password".
**Learning:** UX-friendly features like "auto-switching to signup" or "real-time availability checks" can inadvertently leak user existence, which is a privacy risk and aids brute-force attacks.
**Prevention:** Use unified error messages for authentication (e.g., "Invalid email or password"). Avoid real-time existence checks on public forms.
## 2025-05-23 - Hardcoded Supabase Service Role Key
**Vulnerability:** Hardcoded administrative keys (Supabase Service Role Key) in the codebase.
**Learning:** Hardcoding the Service Role Key in a client-side application (Flutter) is extremely dangerous as it bypasses Row Level Security (RLS) and can be easily extracted from the compiled binary.
**Prevention:** Always use environment variables (e.g., `String.fromEnvironment`) and ensure sensitive administrative keys are NEVER included in the client-side code if they can be avoided. Use Edge Functions or a backend proxy for operations requiring administrative privileges.
