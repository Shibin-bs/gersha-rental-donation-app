# Firebase Setup Checklist

## Critical Steps to Fix Authentication Issues

### 1. Firebase Console Setup

#### Enable Authentication Methods:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Authentication** → **Sign-in method**
4. **Enable Email/Password**:
   - Click on "Email/Password"
   - Toggle "Enable" to ON
   - Click "Save"
5. **Enable Phone Authentication** (optional):
   - Click on "Phone"
   - Toggle "Enable" to ON
   - Click "Save"

### 2. Firestore Database Setup

1. Go to **Firestore Database** in Firebase Console
2. **Create Database** (if not already created):
   - Click "Create database"
   - Choose "Start in test mode" (for development)
   - Select a location
   - Click "Enable"

3. **Set Security Rules** (Important!):
   Go to **Firestore Database** → **Rules** and set:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can read/write their own data
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
      // Allow creation during signup
      allow create: if request.auth != null;
    }
    
    // Listings collection - authenticated users can read approved listings
    match /listings/{listingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.ownerId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Transactions collection
    match /transactions/{transactionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (resource.data.ownerId == request.auth.uid || 
         resource.data.receiverId == request.auth.uid);
    }
    
    // App settings (for sample data flag)
    match /app_settings/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Only backend can write
    }
  }
}
```

### 3. Check google-services.json

1. Verify `android/app/google-services.json` exists
2. Make sure it contains your Firebase project configuration
3. If missing, download it from:
   - Firebase Console → Project Settings → Your apps → Android app
   - Download `google-services.json`
   - Place it in `android/app/` directory

### 4. Verify Firebase Initialization

The app should print debug messages when starting:
- `🔵 [FirebaseService] Initializing Firebase...`
- `✅ [FirebaseService] Firebase Core initialized`
- `✅ [FirebaseService] Firestore initialized`
- `✅ [FirebaseService] Firebase Auth initialized`

### 5. Common Issues

#### Issue: "Email/Password sign-in is disabled"
**Solution**: Enable Email/Password in Firebase Console → Authentication → Sign-in method

#### Issue: "Permission denied" errors
**Solution**: Update Firestore security rules (see step 2 above)

#### Issue: "User document not found"
**Solution**: 
- Check Firestore rules allow user creation
- Check if `users` collection exists
- Verify user document is being created (check Firestore console)

#### Issue: "Firebase not initialized"
**Solution**: 
- Check `google-services.json` exists
- Verify Firebase project is properly configured
- Check app logs for initialization errors

### 6. Testing Steps

1. **Check Debug Logs**: 
   - Run app with `flutter run`
   - Watch console for debug messages (🔵, ✅, ❌, ⚠️)
   - These will show exactly where the process is failing

2. **Test Sign Up**:
   - Try creating a new account
   - Check Firestore Console → `users` collection
   - Verify document is created with correct UID

3. **Test Sign In**:
   - Try signing in with created account
   - Check debug logs for any errors

### 7. Debug Logs to Watch For

When you run the app, you should see these logs:

**On App Start:**
```
🔵 [FirebaseService] Initializing Firebase...
✅ [FirebaseService] Firebase Core initialized
✅ [FirebaseService] Firestore initialized
✅ [FirebaseService] Firebase Auth initialized
✅ [FirebaseService] Firebase initialization complete
```

**On Sign Up:**
```
🔵 [AuthProvider] Sign up requested for: user@example.com
🔵 [AuthService] Starting sign up for: user@example.com
✅ [AuthService] Firebase Auth user created: [uid]
✅ [AuthService] User document created in Firestore
✅ [AuthService] User document retrieved successfully
✅ [AuthProvider] Sign up successful, user: user@example.com
```

**On Sign In:**
```
🔵 [AuthProvider] Sign in requested for: user@example.com
🔵 [AuthService] Starting sign in for: user@example.com
✅ [AuthService] Firebase Auth sign in successful: [uid]
✅ [AuthService] User document found
✅ [AuthService] Sign in successful, user: user@example.com
✅ [AuthProvider] Sign in successful, user: user@example.com
```

If you see ❌ (red X) messages, that's where the error is occurring!
