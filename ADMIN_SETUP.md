# Admin Account Setup Guide

This guide explains how to create an admin account for the ALU Startup Connect app.

## How Admin Works

Any account whose email ends with **`@aluadmin.com`** is treated as an admin.  
Admin accounts cannot self-register through the app — they must be created manually in Firebase Console.

---

## Step 1 — Create the Admin User in Firebase Auth

1. Open the [Firebase Console](https://console.firebase.google.com/)
2. Select project **`alu-startup-connect-e9b69`**
3. Go to **Authentication → Users → Add user**
4. Enter:
   - **Email**: `admin@aluadmin.com` (or any `name@aluadmin.com` address)
   - **Password**: choose a strong password
5. Click **Add user** and copy the generated **UID**

---

## Step 2 — Create the Admin Firestore Document

1. In Firebase Console, go to **Firestore Database**
2. Navigate to the `users` collection (create it if it doesn't exist yet)
3. Click **Add document**, set the **Document ID** to the UID you copied above
4. Add these fields:

| Field | Type | Value |
|-------|------|-------|
| `name` | string | `Admin` |
| `email` | string | `admin@aluadmin.com` |
| `role` | string | `admin` |
| `status` | string | `active` |
| `createdAt` | timestamp | *(current time)* |

5. Click **Save**

---

## Step 3 — Log In

Open the app and sign in with the admin credentials.  
The app will detect the `@aluadmin.com` domain and redirect you directly to the **Admin Dashboard**.

---

## Deploy Firestore Security Rules

If you have the Firebase CLI installed:

```bash
cd path/to/alu-startup-connect
firebase deploy --only firestore:rules
```

If you don't have the CLI:
1. Open Firebase Console → **Firestore Database → Rules**
2. Paste the contents of [`firestore.rules`](./firestore.rules)
3. Click **Publish**

---

## Adding More Admins

Simply repeat Steps 1 & 2 with any `name@aluadmin.com` email address.  
No code changes are required — the domain check is automatic.
