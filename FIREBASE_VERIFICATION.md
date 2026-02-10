# Firebase Configuration Verification

## ✅ Configuration Checklist

### 1. google-services.json
- ✅ File location: `android/app/google-services.json`
- ✅ Project ID: `gersha-a6677`
- ✅ Package name: `com.example.gersha`
- ✅ SHA-1 certificate hash: `ce33f0851ac8ebc6b52f981ae7d53a03934a66b8`

### 2. Android Build Configuration
- ✅ Google Services plugin added in `android/app/build.gradle.kts`
- ✅ Google Services classpath in `android/build.gradle.kts`
- ✅ Package name matches: `com.example.gersha`

### 3. Firebase Console Setup Required

#### Enable Authentication:
1. Go to [Firebase Console](https://console.firebase.google.com/project/gersha-a6677)
2. Navigate to **Authentication** → **Sign-in method**
3. **Enable Email/Password**:
   - Click "Email/Password"
   - Toggle "Enable" to ON
   - Click "Save"

#### Firestore Database:
1. Go to **Firestore Database**
2. If not created, click "Create database"
3. Choose "Start in test mode" for development
4. Select a location (preferably close to your users)
5. Click "Enable"

#### Firestore Security Rules:
Go to **Firestore Database** → **Rules** and update:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
      allow update: if request.auth != null && request.auth.uid == userId;
    }
    
    // Listings collection
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
    
    // App settings
    match /app_settings/{document=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

### 4. Testing the Configuration

After running the app, check the debug console for:

**Expected Success Messages:**
```
🔵 [FirebaseService] Initializing Firebase...
🔵 [FirebaseService] Project ID: gersha-a6677
🔵 [FirebaseService] Package: com.example.gersha
✅ [FirebaseService] Firebase Core initialized
✅ [FirebaseService] Firebase App Name: [DEFAULT]
✅ [FirebaseService] Firebase App Options: gersha-a6677
✅ [FirebaseService] Firestore initialized
✅ [FirebaseService] Firebase Auth initialized
✅ [FirebaseService] Firebase Storage initialized
✅ [FirebaseService] Firebase initialization complete
```

**If you see errors:**
- ❌ "Failed to initialize Firebase" → Check google-services.json location
- ❌ "Permission denied" → Update Firestore security rules
- ❌ "Email/Password sign-in is disabled" → Enable in Firebase Console

### 5. Next Steps

1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test sign up:**
   - Try creating a new account
   - Watch debug logs for any errors
   - Check Firestore Console to verify user document is created

3. **Test sign in:**
   - Sign in with the created account
   - Verify navigation works correctly

### 6. Common Issues

**Issue: "SHA-1 certificate mismatch"**
- Solution: Make sure you added the correct SHA-1 fingerprint
- For debug: Use `keytool -list -v -keystore ~/.android/debug.keystore`
- For release: Use your release keystore

**Issue: "Package name mismatch"**
- Solution: Ensure `applicationId` in `build.gradle.kts` matches `package_name` in `google-services.json`

**Issue: "Firebase not initialized"**
- Solution: Verify `google-services.json` is in `android/app/` directory
- Solution: Clean and rebuild the project
