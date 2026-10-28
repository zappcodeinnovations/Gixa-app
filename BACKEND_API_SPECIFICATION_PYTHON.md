# EduTrack (Gixa) - Backend API Specification (Python / Django / FastAPI)

This document is the official backend integration specification for **Python Backend Developers** (Django REST Framework / FastAPI) supporting the **EduTrack (Gixa)** mobile app.

---

## 1. Global Backend Architecture & Standards

### 1.1 Base Configuration
- **Base URL:** `https://admin.gixa.in`
- **Default Headers:**
  ```http
  Accept: application/json
  Content-Type: application/json
  Authorization: Bearer <access_token>  # Required for protected routes
  ```
- **Single-Device & Session Security:**
  - JWT Access Token payload contains: `user_id`, `token_type: "access"`, `exp`, `iat`, `jti`, and `token_version`.
  - When user logs in on a new device, `token_version` or device session ID is incremented/checked to enforce single-device active session limits.

### 1.2 Standard Response Envelopes
#### Standard Success Response:
```json
{
  "success": true,
  "message": "Operation completed successfully.",
  "data": {}
}
```

#### Standard Paginated Response:
```json
{
  "success": true,
  "count": 125,
  "total_pages": 7,
  "has_next": true,
  "current_page": 1,
  "results": []
}
```

#### Standard Error Response:
```json
{
  "success": false,
  "message": "Human-readable error description.",
  "error_code": "INVALID_OTP",
  "errors": {
    "field_name": ["Specific field error."]
  }
}
```

---

## 2. Authentication & Session Module

### 2.1 Send OTP
- **HTTP Method:** `POST`
- **Route:** `/api/student/send-otp/`
- **Auth:** Public (No token)
- **Request Body:**
  ```json
  {
    "mobile_number": "9876543210"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "OTP sent successfully.",
    "data": {
      "mobile_number": "9876543210",
      "otp_expiry_seconds": 60,
      "resend_available_in": 30
    }
  }
  ```
- **Backend Business Logic:**
  1. Validate 10-digit Indian mobile number format.
  2. Generate a cryptographically secure 4 or 6-digit OTP.
  3. Store OTP in Redis/Database with a 60-second TTL and rate-limiting (max 3 attempts per 10 minutes).
  4. Dispatch SMS via SMS Gateway (e.g. Twilio / MSG91).
- **Client Trigger:** User enters mobile number on `LoginWithOtpPage` and taps "Get OTP".

---

### 2.2 Verify OTP
- **HTTP Method:** `POST`
- **Route:** `/api/student/verify-otp/`
- **Auth:** Public (No token)
- **Request Body:**
  ```json
  {
    "mobile_number": "9876543210",
    "otp": "123456",
    "device_id": "optional-uuid-string"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Login successful.",
    "data": {
      "is_new_user": false,
      "is_profile_completed": true,
      "user_id": 272,
      "tokens": {
        "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      },
      "user": {
        "id": 272,
        "name": "Aman Sharma",
        "mobile_number": "9876543210",
        "email": "aman@example.com"
      }
    }
  }
  ```
- **Error Response (409 Conflict - Concurrent Device):**
  ```json
  {
    "success": false,
    "code": "ALREADY_LOGGED_IN",
    "message": "Account already logged in on another device.",
    "device_info": "Samsung SM-G998B"
  }
  ```
- **Backend Business Logic:**
  1. Verify OTP against Redis/DB. Invalidate OTP immediately upon successful verification.
  2. If user doesn't exist, create user record and flag `is_new_user: true`.
  3. Issue signed JWT Access Token (short-lived, e.g., 2 hours) and Refresh Token (long-lived, e.g., 30 days).
  4. Client routes to `RegisterPage` if `is_profile_completed == false`, or `MainNavPage` (Home) if `true`.

---

### 2.3 Refresh Token
- **HTTP Method:** `POST`
- **Route:** `/api/student/refresh-token/`
- **Auth:** Public
- **Request Body:**
  ```json
  {
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "access": "new_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh": "new_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```
- **Backend Business Logic:**
  1. Validate refresh token signature, expiry, and check if blacklisted.
  2. Check `token_version` to ensure session has not been revoked.
  3. Issue a fresh Access Token (and optional rotated Refresh Token).

---

### 2.4 Logout
- **HTTP Method:** `POST`
- **Route:** `/api/logout/`
- **Auth:** Bearer Token
- **Request Body:** `{}`
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Logged out successfully."
  }
  ```
- **Backend Business Logic:**
  1. Blacklist current refresh token in Redis/DB.
  2. Invalidate active device push notification token (FCM).

---

### 2.5 Logout Other Device
- **HTTP Method:** `POST`
- **Route:** `/api/logout-other-device/`
- **Auth:** Public or Bearer Token
- **Request Body:**
  ```json
  {
    "mobile_number": "9876543210",
    "device_id": "current-device-uuid"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Other devices logged out successfully."
  }
  ```
- **Backend Business Logic:**
  1. Increments `token_version` for user in DB.
  2. Revokes all previous active sessions except the specified `device_id`.

---

### 2.6 App Version Check
- **HTTP Method:** `GET`
- **Route:** `/app/version-check/`
- **Auth:** Public
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "minimum_version": "1.0.4",
    "latest_version": "1.0.6",
    "force_update": false,
    "update_url_android": "https://play.google.com/store/apps/details?id=com.edutrack.app",
    "update_url_ios": "https://apps.apple.com/app/id123456789",
    "release_notes": "Bug fixes and performance improvements."
  }
  ```
- **Client Trigger:** Called on `SplashScreen` launch. If `force_update == true`, blocks user until they update.

---

## 3. Student Registration & Profile Module

### 3.1 Registration Masters Data
- **HTTP Method:** `GET`
- **Route:** `/api/masters/`
- **Auth:** Public / Bearer Token
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "states": [
        {"id": 1, "name": "Maharashtra", "code": "MH"},
        {"id": 2, "name": "Karnataka", "code": "KA"}
      ],
      "categories": [
        {"id": 1, "name": "General", "code": "UR"},
        {"id": 2, "name": "OBC-NCL", "code": "OBC"},
        {"id": 3, "name": "SC", "code": "SC"},
        {"id": 4, "name": "ST", "code": "ST"},
        {"id": 5, "name": "EWS", "code": "EWS"}
      ],
      "quotas": [
        {"id": 1, "name": "All India Quota", "code": "AIQ"},
        {"id": 2, "name": "State Quota", "code": "SQ"},
        {"id": 3, "name": "Management / NRI Quota", "code": "MQ"}
      ],
      "courses": [
        {"id": 1, "name": "MBBS", "code": "MBBS"},
        {"id": 2, "name": "BDS", "code": "BDS"}
      ],
      "genders": ["Male", "Female", "Other"]
    }
  }
  ```
- **Client Trigger:** Populates dropdown selectors on `RegisterPage` and `EditProfileView`.

---

### 3.2 Register Student
- **HTTP Method:** `POST`
- **Route:** `/api/student/register/`
- **Auth:** Bearer Token or OTP Session Key
- **Request Body:**
  ```json
  {
    "full_name": "Rohan Deshmukh",
    "email": "rohan@example.com",
    "neet_roll_no": "1234567890",
    "neet_score": 620,
    "neet_air_rank": 14250,
    "domicile_state_id": 1,
    "category_id": 2,
    "gender": "Male",
    "target_course": "MBBS"
  }
  ```
- **Success Response (201 Created):**
  ```json
  {
    "success": true,
    "message": "Student registration completed.",
    "data": {
      "student_id": 581,
      "full_name": "Rohan Deshmukh",
      "profile_completed": true
    }
  }
  ```

---

### 3.3 Get Student Profile
- **HTTP Method:** `GET`
- **Route:** `/api/student/profile/`
- **Auth:** Bearer Token
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "id": 272,
      "full_name": "Rohan Deshmukh",
      "mobile_number": "9876543210",
      "email": "rohan@example.com",
      "profile_image": "https://s3.amazonaws.com/gixa-bucket/avatars/272.jpg",
      "neet_score": 620,
      "neet_air_rank": 14250,
      "domicile_state": "Maharashtra",
      "category": "OBC",
      "subscription": {
        "is_active": true,
        "plan_name": "Premium All India Counseling",
        "expiry_date": "2026-12-31"
      }
    }
  }
  ```

---

### 3.4 Update Student Profile & Avatar
- **HTTP Method:** `PUT` / `PATCH`
- **Route:** `/api/student/profile/`
- **Content-Type:** `multipart/form-data`
- **Form Data Fields:**
  - `full_name`: string
  - `email`: string
  - `neet_score`: integer
  - `neet_air_rank`: integer
  - `domicile_state`: integer (State ID)
  - `category`: integer (Category ID)
  - `profile_image`: file (binary image/jpeg or image/png) [Optional]
- **Success Response (200 OK):** Returns updated student profile object.

---

### 3.5 Remove Profile Image
- **HTTP Method:** `POST`
- **Route:** `/api/student/profile/remove-image/`
- **Auth:** Bearer Token
- **Request Body:** `{}`
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Profile image removed successfully."
  }
  ```

---

## 4. Colleges & Cutoff Explorer Module

### 4.1 Search & Filter Colleges
- **HTTP Method:** `GET`
- **Route:** `/api/colleges`
- **Auth:** Bearer Token / Public
- **Query Parameters:**
  - `page`: integer (default: 1)
  - `search`: string (search term by college name, city)
  - `state`: string / ID
  - `city`: string
  - `institute_type`: string (`Government`, `Private`, `Deemed`)
  - `quota`: string (`AIQ`, `State Quota`)
  - `course`: string (`MBBS`, `BDS`, `MD`)
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "count": 706,
    "total_pages": 36,
    "has_next": true,
    "results": [
      {
        "id": 105,
        "name": "All India Institute of Medical Sciences (AIIMS)",
        "short_name": "AIIMS New Delhi",
        "city": "New Delhi",
        "state": "Delhi",
        "institute_type": "Government",
        "established_year": 1956,
        "total_seats": 125,
        "hospital_beds": 2478,
        "logo_url": "https://s3.../aiims_logo.png",
        "cover_image": "https://s3.../aiims_campus.jpg",
        "annual_tuition_fee": 1628.00,
        "is_favourite": false
      }
    ]
  }
  ```

---

### 4.2 College Detailed Profile
- **HTTP Method:** `GET`
- **Route:** `/api/college/{id}/`
- **Auth:** Bearer Token / Public
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "id": 105,
      "name": "AIIMS New Delhi",
      "overview": "Premier public medical research university...",
      "campus_facilities": ["Hostel", "Library", "Auditorium", "Gym", "Cafeteria"],
      "hospital_details": {
        "beds_count": 2478,
        "daily_opd_patient_flow": 12000,
        "icu_beds": 280
      },
      "courses_offered": [
        {"course_code": "MBBS", "intake": 125, "duration_years": 5.5},
        {"course_code": "MD_RADIO", "intake": 12, "duration_years": 3.0}
      ],
      "contact": {
        "phone": "+91-11-26588500",
        "email": "info@aiims.edu",
        "website": "https://www.aiims.edu"
      }
    }
  }
  ```

---

### 4.3 Category Cutoff Analytics
- **HTTP Method:** `GET`
- **Route:** `/api/college/{id}/category-cutoff/`
- **Auth:** Bearer Token
- **Query Parameters:** `year=2024&quota=AIQ&course=MBBS`
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "college_id": 105,
    "year": 2024,
    "rounds": [
      {
        "round_number": 1,
        "cutoffs": [
          {"category": "UR", "opening_rank": 1, "closing_rank": 57, "closing_score": 715},
          {"category": "OBC", "opening_rank": 62, "closing_rank": 247, "closing_score": 705},
          {"category": "SC", "opening_rank": 310, "closing_rank": 1420, "closing_score": 680},
          {"category": "ST", "opening_rank": 1500, "closing_rank": 3100, "closing_score": 655},
          {"category": "EWS", "opening_rank": 80, "closing_rank": 220, "closing_score": 706}
        ]
      }
    ]
  }
  ```

---

### 4.4 Seat Matrix
- **HTTP Method:** `GET`
- **Route:** `/api/seat-matrix/`
- **Auth:** Bearer Token
- **Query Parameters:** `state=Maharashtra&course=MBBS`
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "total_seats": 4850,
    "data": [
      {
        "college_id": 12,
        "college_name": "Grant Medical College, Mumbai",
        "govt_seats": 250,
        "aiq_15_percent": 38,
        "state_85_percent": 212
      }
    ]
  }
  ```

---

## 5. Favourite Colleges Module

### 5.1 Add Favourite College
- **HTTP Method:** `POST`
- **Route:** `/api/student/favourite-colleges/`
- **Auth:** Bearer Token
- **Request Body:**
  ```json
  {
    "college_id": 105
  }
  ```
- **Success Response (201 Created):**
  ```json
  {
    "success": true,
    "message": "College added to favourites."
  }
  ```

---

### 5.2 Remove Favourite College
- **HTTP Method:** `POST`
- **Route:** `/api/student/favourite-colleges/remove/`
- **Auth:** Bearer Token
- **Request Body:**
  ```json
  {
    "college_id": 105
  }
  ```

---

### 5.3 List Favourite Colleges
- **HTTP Method:** `GET`
- **Route:** `/api/student/favourite-colleges/`
- **Auth:** Bearer Token
- **Success Response (200 OK):** Returns array of favorite college summary cards.

---

## 6. College Comparison Module

### 6.1 Compare Colleges
- **HTTP Method:** `POST`
- **Route:** `/api/colleges/compare/`
- **Auth:** Bearer Token
- **Request Body:**
  ```json
  {
    "college_ids": [105, 112, 140]
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "comparison": [
      {
        "college_id": 105,
        "name": "AIIMS New Delhi",
        "fees": 1628,
        "beds": 2478,
        "closing_rank_ur": 57,
        "patient_opd": 12000,
        "established": 1956
      },
      {
        "college_id": 112,
        "name": "Maulana Azad Medical College",
        "fees": 4500,
        "beds": 2800,
        "closing_rank_ur": 98,
        "patient_opd": 9500,
        "established": 1958
      }
    ]
  }
  ```

---

### 6.2 Save Comparison to Cloud History
- **HTTP Method:** `POST`
- **Route:** `/api/colleges/compare/save/`
- **Auth:** Bearer Token
- **Request Body:**
  ```json
  {
    "comparison_title": "AIIMS vs MAMC vs VMMC",
    "college_ids": [105, 112, 140]
  }
  ```

---

### 6.3 Get Comparison History & Delete
- **Routes:**
  - `GET /api/colleges/compare/history/` -> Lists saved comparisons with creation timestamps.
  - `POST /api/colleges/compare/delete/` -> Request: `{"id": 42}` deletes comparison session.

---

## 7. AI Rank Prediction Module

### 7.1 Predict Colleges (Flagship AI Endpoint)
- **HTTP Method:** `POST`
- **Route:** `/api/prediction/`
- **Auth:** Bearer Token
- **Request Body:**
  ```json
  {
    "neet_air_rank": 14250,
    "neet_score": 620,
    "category": "OBC",
    "domicile_state": "Maharashtra",
    "quota": "State Quota",
    "course": "MBBS",
    "preferred_states": ["Maharashtra", "Karnataka"]
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "prediction_summary": {
      "high_chance_count": 8,
      "medium_chance_count": 14,
      "low_chance_count": 5
    },
    "results": [
      {
        "college_id": 88,
        "college_name": "Government Medical College, Nagpur",
        "state": "Maharashtra",
        "probability_tier": "HIGH",
        "probability_percentage": 94,
        "previous_year_closing_rank": 16800,
        "quota": "State Quota",
        "category": "OBC",
        "annual_fee": 125000.00
      },
      {
        "college_id": 92,
        "college_name": "BJ Government Medical College, Pune",
        "state": "Maharashtra",
        "probability_tier": "MEDIUM",
        "probability_percentage": 68,
        "previous_year_closing_rank": 13900,
        "quota": "State Quota",
        "category": "OBC",
        "annual_fee": 125000.00
      }
    ]
  }
  ```
- **Backend Business Logic:**
  1. Check that the student has an active subscription plan allowing AI prediction for the target states.
  2. Query historical round 1, round 2, and mop-up cutoff records against current year percentile/score shifts.
  3. Classify colleges into `HIGH` (AIR significantly better than cutoff), `MEDIUM` (AIR within ±5% buffer of cutoff), and `LOW` (ambitious reach).

---

### 7.2 State-wise Availability for Prediction
- **HTTP Method:** `GET`
- **Route:** `/api/prediction/statewise-availability/`
- **Auth:** Bearer Token
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "total_states": 2,
    "data": [
      {
        "state": "West Bengal",
        "available_categories": ["UR", "OBC-A", "OBC-B", "SC", "ST", "EWS"],
        "available_quotas": ["State Quota", "Management Quota"],
        "open_category_reference": {
          "alias_codes": ["GEN", "GENERAL", "UR", "OPEN"]
        }
      }
    ],
    "selected_courses": [
      {"id": 1, "course_name": "MBBS"}
    ]
  }
  ```

---

### 7.3 NEET Score to Rank Predictor
- **HTTP Method:** `GET`
- **Route:** `/api/neet-rank-predictor/?score={score}`
- **Auth:** Public / Bearer Token
- **Query Parameters:** `score`: integer (0 to 720)
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "score": 620,
    "predicted_rank_min": 13800,
    "predicted_rank_max": 14950,
    "percentile": 99.12
  }
  ```

---

### 7.4 Prediction Sheets
- **HTTP Method:** `GET`
- **Route:** `/api/student/prediction-sheets/`
- **Auth:** Bearer Token
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "sheets": [
      {
        "id": 101,
        "title": "NEET 2024 AIQ MBBS Choice Preference List",
        "file_url": "https://s3.../prediction_sheets/sheet_101.pdf",
        "generated_at": "2024-08-15T10:30:00Z",
        "status": "Ready"
      }
    ]
  }
  ```

---

## 8. Subscriptions & Payment Gateway Module

### 8.1 Subscription Plans
- **HTTP Method:** `GET`
- **Route:** `/subscription-plans/`
- **Auth:** Public / Bearer Token
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "plans": [
      {
        "id": 1,
        "name": "State Counseling Starter",
        "price": 4999.00,
        "discounted_price": 2999.00,
        "state_limit": 1,
        "features": [
          "AI College Predictor",
          "Cutoff Analytics",
          "PDF Choice Filling List"
        ]
      },
      {
        "id": 2,
        "name": "All India + 3 States Pro",
        "price": 14999.00,
        "discounted_price": 9999.00,
        "state_limit": 3,
        "features": [
          "Dedicated Expert Counselor Call",
          "Choice Filling Assistance",
          "Direct WhatsApp Support",
          "Unlimited AI Predictions"
        ]
      }
    ]
  }
  ```

---

### 8.2 Create Razorpay Order
- **HTTP Method:** `POST`
- **Route:** `/api/student/subscription/create-order/`
- **Auth:** Bearer Token
- **Request Body:**
  ```json
  {
    "plan_id": 2,
    "applied_coupon": "NEET2026"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "order_id": "order_MNb76TgFd43e",
    "amount_in_paise": 999900,
    "currency": "INR",
    "razorpay_key_id": "rzp_live_abc123XYZ",
    "prefill": {
      "name": "Rohan Deshmukh",
      "email": "rohan@example.com",
      "contact": "9876543210"
    }
  }
  ```
- **Backend Business Logic:**
  1. Call Razorpay REST API (`/v1/orders`) to generate `order_id`.
  2. Save pending transaction in local database with status `PENDING`.

---

### 8.3 Verify Razorpay Payment Signature
- **HTTP Method:** `POST`
- **Route:** `/api/student/subscription/verify-payment/`
- **Auth:** Bearer Token
- **Request Body:**
  ```json
  {
    "razorpay_payment_id": "pay_MNb99AbCd123",
    "razorpay_order_id": "order_MNb76TgFd43e",
    "razorpay_signature": "e2a45fb34901dc89b..."
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Payment verified and subscription activated.",
    "subscription": {
      "subscription_id": 490,
      "plan_name": "All India + 3 States Pro",
      "status": "ACTIVE",
      "valid_until": "2026-12-31T23:59:59Z"
    }
  }
  ```
- **Backend Business Logic:**
  1. Verify HMAC-SHA256 signature using Razorpay Key Secret:
     `generated_signature = hmac_sha256(order_id + "|" + payment_id, secret)`
  2. Check if signature matches `razorpay_signature`.
  3. Mark order as `PAID`.
  4. Activate student's subscription and dispatch invoice email and confirmation SMS.

---

### 8.4 Subscription Selected States
- **HTTP Methods:**
  - `GET /api/student/subscription/states/` -> Returns states currently chosen under package.
  - `POST /api/student/subscription/states/` -> Request: `{"state_ids": [1, 2]}`. Validates that number of chosen states does not exceed `state_limit` of the active package.

---

### 8.5 App Store Review Verification Flag
- **HTTP Method:** `GET`
- **Route:** `/api/app-verification/`
- **Auth:** Public
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "in_review": false
  }
  ```
- **Backend Business Logic:**
  - When submitting iOS builds to Apple App Store, backend sets `in_review: true`. This instructs the Flutter app to hide external Razorpay payment buttons to comply with Apple App Store Review Guideline 3.1.1.

---

## 9. Counselor & Guidance Assistance Module

### 9.1 Counselors Directory
- **HTTP Method:** `GET`
- **Route:** `/api/assistance/counselors/`
- **Auth:** Bearer Token
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "counselors": [
      {
        "id": 14,
        "name": "Dr. Pradeep Mishra",
        "designation": "Chief NEET Admission Strategist",
        "experience_years": 12,
        "rating": 4.9,
        "languages": ["English", "Hindi"],
        "photo_url": "https://s3.../counselors/14.jpg",
        "total_consultations": 1450
      }
    ]
  }
  ```

---

### 9.2 Request Guidance (Appointment Booking)
- **HTTP Method:** `POST`
- **Route:** `/api/request-guidance/`
- **Auth:** Bearer Token
- **Request Body:**
  ```json
  {
    "counselor_id": 14,
    "preferred_date": "2026-09-28",
    "preferred_time_slot": "15:00 - 16:00",
    "query_topic": "Choice filling between GMC Nagpur vs KIMS Hubli",
    "contact_phone": "9876543210"
  }
  ```
- **Success Response (201 Created):**
  ```json
  {
    "success": true,
    "message": "Guidance request submitted.",
    "request_id": 892,
    "status": "Pending Confirmation"
  }
  ```

---

## 10. Document Management Module

### 10.1 Upload Document
- **HTTP Method:** `POST`
- **Route:** `/api/student/documents/upload/`
- **Auth:** Bearer Token
- **Content-Type:** `multipart/form-data`
- **Form Data Fields:**
  - `document_type`: string (`neet_admit_card`, `neet_scorecard`, `class_10_marksheet`, `class_12_marksheet`, `domicile_certificate`, `category_certificate`)
  - `file`: binary (PDF, JPG, PNG - max 5MB)
- **Success Response (201 Created):**
  ```json
  {
    "success": true,
    "message": "Document uploaded successfully.",
    "data": {
      "id": 312,
      "document_type": "neet_scorecard",
      "file_url": "https://s3.../documents/272/scorecard.pdf",
      "verification_status": "PENDING",
      "uploaded_at": "2026-09-24T18:00:00Z"
    }
  }
  ```

---

### 10.2 List Student Documents
- **HTTP Method:** `GET`
- **Route:** `/api/student/documents/`
- **Auth:** Bearer Token
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "documents": [
      {
        "id": 312,
        "document_type": "neet_scorecard",
        "file_url": "https://s3.../scorecard.pdf",
        "verification_status": "VERIFIED",
        "admin_remarks": null
      }
    ]
  }
  ```

---

## 11. Chatbot & Admission Chat Support Module

### 11.1 Start Chat Session
- **HTTP Method:** `POST`
- **Route:** `/api/chat/start/` (or `/api/chat/admission/`)
- **Auth:** Bearer Token
- **Request Body:**
  ```json
  {
    "entry_flow": "admission_counseling",
    "context": {
      "neet_score": 620,
      "state": "Maharashtra"
    }
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "session_id": "chat_sess_8917234",
    "initial_message": "Hello Rohan! I see your NEET score is 620. How can I help you with your college counseling today?",
    "suggested_prompts": [
      "What colleges can I get in Maharashtra?",
      "What is the fees for KIMS?",
      "Connect me to an expert counselor"
    ]
  }
  ```

---

### 11.2 Bot Automated Response & User Message
- **HTTP Method:** `POST`
- **Route:** `/api/chat/message/` (or `/api/chat/bot-response/`)
- **Auth:** Bearer Token
- **Request Body:**
  ```json
  {
    "session_id": "chat_sess_8917234",
    "sender": "user",
    "message": "Can I get GMC Mumbai with 620 in OBC?"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message_id": "msg_90123",
    "sender": "bot",
    "reply": "Based on 2024 Round 2 cutoffs for GMC Mumbai (Grant Medical College), the closing rank for OBC was 11,400 (~635 marks). At 620 marks, your chance is Moderate in mop-up rounds. Would you like to see alternative GMCs?",
    "timestamp": "2026-09-24T18:10:00Z"
  }
  ```

---

### 11.3 Hand-off from Bot to Human Counselor
- **HTTP Method:** `POST`
- **Route:** `/api/chat/switch-to-human/`
- **Auth:** Bearer Token
- **Request Body:**
  ```json
  {
    "session_id": "chat_sess_8917234",
    "reason": "Complex NRI quota inquiry"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "status": "QUEUED_FOR_AGENT",
    "assigned_agent_name": "Counselor Priya",
    "message": "You are now connected with Counselor Priya. She will reply shortly."
  }
  ```

---

## 12. Support & Helpdesk Tickets Module

### 12.1 Create Ticket
- **HTTP Method:** `POST`
- **Route:** `/api/tickets/create/`
- **Auth:** Bearer Token
- **Content-Type:** `multipart/form-data`
- **Form Data Fields:**
  - `subject`: string (e.g. "Payment deducted but subscription not active")
  - `category`: string (`Payment`, `Prediction`, `Counselor`, `Technical`)
  - `description`: string
  - `attachment`: file (binary image/screenshot) [Optional]
- **Success Response (201 Created):**
  ```json
  {
    "success": true,
    "message": "Ticket created successfully.",
    "ticket_id": "TCK-8812",
    "status": "OPEN"
  }
  ```

---

### 12.2 Ticket Thread & Reply
- **HTTP Methods:**
  - `GET /api/tickets/` -> Lists all student tickets.
  - `GET /api/tickets/{id}/` -> Returns ticket details and message history between student & admin.
  - `POST /api/tickets/reply/` -> Multipart/Form request with `ticket_id`, `message`, and optional `attachment`.

---

## 13. Summary Table for Python Backend Developers

| Method | Endpoint | Auth | Request Type | Target Service / Model |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/student/send-otp/` | None | JSON | OTP Service / Redis Cache |
| `POST` | `/api/student/verify-otp/` | None | JSON | Auth / JWT Token Generator |
| `POST` | `/api/student/refresh-token/` | None | JSON | JWT Token Refresh / Blacklist |
| `POST` | `/api/logout/` | Bearer | JSON | Token Blacklist |
| `GET` | `/app/version-check/` | None | None | AppConfig Model |
| `GET` | `/api/masters/` | None | None | Masters (States, Quotas, Categories) |
| `POST` | `/api/student/register/` | Bearer | JSON | StudentProfile Model |
| `GET/PUT`| `/api/student/profile/` | Bearer | JSON / Multipart | StudentProfile Model |
| `GET` | `/api/colleges` | Public | Query Params | College Directory (Elasticsearch/Postgres) |
| `GET` | `/api/college/{id}/` | Public | Path Param | College Model |
| `GET` | `/api/college/{id}/category-cutoff/` | Bearer | Path / Query | CutoffRecord Model |
| `POST` | `/api/colleges/compare/` | Bearer | JSON | Comparison Analytics Service |
| `POST` | `/api/prediction/` | Bearer | JSON | AI Cutoff Prediction Engine |
| `GET` | `/api/prediction/statewise-availability/`| Bearer | Query | Subscription States Validator |
| `GET` | `/api/neet-rank-predictor/` | Public | Query Param | Rank Regression Curve Model |
| `GET` | `/subscription-plans/` | Public | None | SubscriptionPlan Model |
| `POST` | `/api/student/subscription/create-order/`| Bearer | JSON | Razorpay API Client |
| `POST` | `/api/student/subscription/verify-payment/`| Bearer | JSON | HMAC-SHA256 Verifier |
| `POST` | `/api/student/documents/upload/` | Bearer | Multipart | AWS S3 / StudentDocument Model |
| `POST` | `/api/chat/start/` | Bearer | JSON | Chatbot Engine / Session Model |
| `POST` | `/api/chat/message/` | Bearer | JSON | Chatbot NLP / Webhook |
| `POST` | `/api/tickets/create/` | Bearer | Multipart | Helpdesk Ticket Model |
