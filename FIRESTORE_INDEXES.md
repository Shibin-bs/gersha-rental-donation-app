# Firestore Composite Indexes Required

This document lists all Firestore composite indexes that need to be created in Firebase Console.

## How to Create Indexes

1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Add the indexes listed below

## Required Indexes

### Listings Collection

1. **Collection:** `listings`
   - Fields: `status` (Ascending), `createdAt` (Descending)
   - Query scope: Collection

2. **Collection:** `listings`
   - Fields: `status` (Ascending), `type` (Ascending), `createdAt` (Descending)
   - Query scope: Collection

3. **Collection:** `listings`
   - Fields: `status` (Ascending), `category` (Ascending), `createdAt` (Descending)
   - Query scope: Collection

4. **Collection:** `listings`
   - Fields: `status` (Ascending), `type` (Ascending), `category` (Ascending), `createdAt` (Descending)
   - Query scope: Collection

5. **Collection:** `listings`
   - Fields: `ownerId` (Ascending), `createdAt` (Descending)
   - Query scope: Collection

### Transactions Collection

1. **Collection:** `transactions`
   - Fields: `ownerId` (Ascending), `startDate` (Descending)
   - Query scope: Collection

2. **Collection:** `transactions`
   - Fields: `receiverId` (Ascending), `startDate` (Descending)
   - Query scope: Collection

3. **Collection:** `transactions`
   - Fields: `listingId` (Ascending), `startDate` (Descending)
   - Query scope: Collection

4. **Collection:** `transactions`
   - Fields: `ownerId` (Ascending), `status` (Ascending), `startDate` (Descending)
   - Query scope: Collection

5. **Collection:** `transactions`
   - Fields: `receiverId` (Ascending), `status` (Ascending), `startDate` (Descending)
   - Query scope: Collection

## Note

If indexes are missing, the app will still work but queries may fail silently and return empty results. The app includes error handling to gracefully handle missing indexes.
