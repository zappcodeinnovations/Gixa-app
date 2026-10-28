# EduTrack (Gixa) - Complete API Usage & Integration Guide

This document provides a comprehensive mapping of every API in the **EduTrack (Gixa)** application:
- **API Endpoint & HTTP Method**
- **WHERE is it used?** (Screens, Views, Controllers, and Services)
- **WHY is it used?** (Exact purpose and functionality in the app)

---

## 1. Authentication & Session Management

### 1.1 Send OTP
- **Endpoint:** `POST /api/student/send-otp/` (`ApiEndpoints.sendOtp`)
- **Service:** `AuthServices.sendOtp()` in `lib/services/auth_services.dart`
- **Controller:** `OtpController.sendOtp()` in `lib/Modules/Auth/controllers/otp_controller.dart`
- **WHERE (Screen):** 
  - `LoginWithOtpPage` (`lib/Modules/Auth/Veiw/login_with_otp_page.dart`)
- **WHY (Purpose):** 
  - Sends a One-Time Password (OTP) to the student's mobile number for passwordless authentication and login.

---

### 1.2 Verify OTP
- **Endpoint:** `POST /api/student/verify-otp/` (`ApiEndpoints.verifyOtp`)
- **Service:** `AuthServices.verifyOtp()` in `lib/services/auth_services.dart`
- **Controller:** `OtpController.verifyOtp()` in `lib/Modules/Auth/controllers/otp_controller.dart`
- **WHERE (Screen):** 
  - `VerifyOtpPage` (`lib/Modules/Auth/Veiw/verify_otp_page.dart`)
- **WHY (Purpose):** 
  - Validates the 4/6 digit OTP entered by the user. If verified, returns the student profile status, JWT Access Token, and Refresh Token. It routes the user either to Registration (if new user) or Home/Main Navigation (if existing user).

---

### 1.3 Refresh Token
- **Endpoint:** `POST /api/student/refresh-token/` (`ApiEndpoints.refreshToken`)
- **Service:** `AuthServices.refreshToken()` in `lib/services/auth_services.dart` & `ApiClient._refreshToken()` in `lib/network/api_client.dart`
- **Controller:** Handled globally by network interceptor / `ApiClient`
- **WHERE (Screen):** 
  - Global / Background network layer (used across all authenticated screens)
- **WHY (Purpose):** 
  - Automatically called when an access token expires (HTTP 401). Refreshes the session silently without forcing the user to log in again.

---

### 1.4 Logout
- **Endpoint:** `POST /api/logout/` (`ApiEndpoints.logout`)
- **Service:** `AuthServices.logout()` in `lib/services/auth_services.dart` & `SessionService` in `lib/services/logout_services.dart`
- **Controller:** `ProfileController`, `SettingsPage`
- **WHERE (Screen):** 
  - `ProfilePage` (`lib/Modules/Profile/views/profile_screen.dart`)
  - `SettingsPage` (`lib/Modules/settings/view/settings_page.dart`)
- **WHY (Purpose):** 
  - Invalidates the current device session on the backend server, clears local secure storage and tokens, and navigates back to the Login screen.

---

### 1.5 Logout Other Device
- **Endpoint:** `POST /api/logout-other-device/` (`ApiEndpoints.logoutOtherDevice`)
- **Service:** `AuthServices.logoutOtherDevice()` in `lib/services/auth_services.dart`
- **Controller:** `OtpController`, `AppStartController`
- **WHERE (Screen):** 
  - `VerifyOtpPage` dialog when concurrent login is detected
- **WHY (Purpose):** 
  - Enforces single-device login policy. If the user is already logged in on another device, this API terminates the previous device session so the current device can log in.

---

### 1.6 App Version Check
- **Endpoint:** `GET /app/version-check/` (`ApiEndpoints.versionCheck`)
- **Service:** `VersionService.checkVersion()` in `lib/services/version_services.dart`
- **Controller:** `VersionController`, `AppStartController`
- **WHERE (Screen):** 
  - `SplashScreen` (`lib/Modules/splash/splash_screen.dart`)
- **WHY (Purpose):** 
  - Checks if the installed app version meets minimum version requirements. If deprecated, triggers a force-update or soft-update modal linking to Google Play / App Store.

---

## 2. Student Registration & Profile

### 2.1 Registration Masters Data
- **Endpoint:** `GET /api/masters/` (`ApiEndpoints.masters`)
- **Service:** `RegisterMasterApi.getMasters()` in `lib/services/register_master_api.dart`
- **Controller:** `RegisterController`, `ProfileController`, `CollegeListController`
- **WHERE (Screen):** 
  - `RegisterPage` (`lib/Modules/register/view/register_page.dart`)
  - `EditProfileView` (`lib/Modules/updateProfile/view/edit_profile_screen.dart`)
- **WHY (Purpose):** 
  - Fetches foundational master dropdown options: States, Categories, Quotas, Sub-categories, and Gender options required to register or update user profile.

---

### 2.2 Register Student
- **Endpoint:** `POST /api/student/register/` (`ApiEndpoints.registerStudent`)
- **Service:** `RegisterApiService.registerStudent()` in `lib/services/register_services.dart`
- **Controller:** `RegisterController.register()` in `lib/Modules/register/controller/register_controller.dart`
- **WHERE (Screen):** 
  - `RegisterPage` (`lib/Modules/register/view/register_page.dart`)
- **WHY (Purpose):** 
  - Submits student onboarding details (Name, Email, NEET Roll No, Score, Rank, State, Category, Domicile, Gender) to create their student record.

---

### 2.3 Get Student Profile
- **Endpoint:** `GET /api/student/profile/` (`ApiEndpoints.profile`)
- **Service:** `ProfileService.fetchProfile()` in `lib/services/profile_services.dart`
- **Controller:** `ProfileController.fetchProfile()` in `lib/Modules/Profile/controllers/profile_controller.dart`
- **WHERE (Screen):** 
  - `ProfilePage` (`lib/Modules/Profile/views/profile_screen.dart`)
  - `HomePage` (`lib/Modules/Home/Veiw/home_page.dart`)
  - `EditProfileView` (`lib/Modules/updateProfile/view/edit_profile_screen.dart`)
- **WHY (Purpose):** 
  - Loads student personal data, avatar URL, NEET scorecard details, subscription status, and counseling state preferences.

---

### 2.4 Update Student Profile
- **Endpoint:** `PUT/PATCH /api/student/profile/` (`ApiEndpoints.profile`)
- **Service:** `UpdateProfileService.updateProfile()` in `lib/services/update_profile_services.dart`
- **Controller:** `UpdateProfileController` in `lib/Modules/updateProfile/controller/update_profile_controller.dart`
- **WHERE (Screen):** 
  - `EditProfileView` (`lib/Modules/updateProfile/view/edit_profile_screen.dart`)
- **WHY (Purpose):** 
  - Allows students to update their profile information, contact details, NEET marks/rank, and upload a new profile picture.

---

### 2.5 Remove Profile Image
- **Endpoint:** `POST /api/student/profile/remove-image/` (`ApiEndpoints.removeProfileImage`)
- **Service:** `ProfileService.removeProfileImage()` in `lib/services/profile_services.dart`
- **Controller:** `ProfileController`, `UpdateProfileController`
- **WHERE (Screen):** 
  - `EditProfileView` (`lib/Modules/updateProfile/view/edit_profile_screen.dart`)
- **WHY (Purpose):** 
  - Deletes the student's avatar image from the server and resets it to the default placeholder.

---

## 3. Colleges & Cutoffs

### 3.1 Fetch Colleges List & Search
- **Endpoint:** `GET /api/colleges` (`ApiEndpoints.colleges`)
- **Service:** `CollegeApiService.fetchColleges()` & `searchCollegesPaginated()` in `lib/services/college_api_service.dart`
- **Controller:** `CollegeListController` in `lib/Modules/Collage/controller/collage_list_controller.dart`, `CollegeSearchController` in `lib/Modules/Search/controller/search_controller.dart`
- **WHERE (Screen):** 
  - `CollegeListPage` (`lib/Modules/Collage/veiw/collage_list_page.dart`)
  - `CollegeSearchPage` (`lib/Modules/Search/veiw/search_page.dart`)
  - `HomePage` (`lib/Modules/Home/Veiw/home_page.dart`)
- **WHY (Purpose):** 
  - Retrieves paginated list of medical/dental colleges with filtering capabilities (state, city, institute type: Govt/Private, quota, fees, course).

---

### 3.2 College Detail View
- **Endpoint:** `GET /api/college/{id}/` (`ApiEndpoints.college`)
- **Service:** `CollegeApiService.fetchCollegeDetail()` in `lib/services/college_api_service.dart`
- **Controller:** `CollegeDetailController` in `lib/Modules/CollageDetails/controller/collage_detail_controller.dart`
- **WHERE (Screen):** 
  - `CollegeDetailPage` (`lib/Modules/CollageDetails/view/collage_details_page.dart`)
- **WHY (Purpose):** 
  - Loads comprehensive details of a specific college: campus facilities, hospital beds, course offerings, approvals (NMC/MCI), contact info, and website.

---

### 3.3 College Category Cutoff
- **Endpoint:** `GET /api/college/{id}/category-cutoff/` (`ApiEndpoints.college`)
- **Service:** `CollegeApiService.fetchCategoryCutoffs()` in `lib/services/college_api_service.dart`
- **Controller:** `CollegeDetailController` in `lib/Modules/CollageDetails/controller/collage_detail_controller.dart`
- **WHERE (Screen):** 
  - `CollegeDetailPage` -> Cutoff tab / section (`lib/Modules/CollageDetails/widgets/cutoff_section.dart`)
- **WHY (Purpose):** 
  - Displays round-wise opening and closing All India Ranks (AIR) and scores across different categories (UR, OBC, SC, ST, EWS, PwD) for previous counseling years.

---

### 3.4 Seat Matrix
- **Endpoint:** `GET /api/seat-matrix/` (`ApiEndpoints.seatMatrix`)
- **Service:** `SeatMatrixService.getSeatMatrix()` in `lib/services/seat_matrix_services.dart`
- **Controller:** `SeatMatrixController` in `lib/Modules/Collage/controller/seat_matrix_controller.dart`
- **WHERE (Screen):** 
  - `CollegeListPage` / Seat Matrix tab
- **WHY (Purpose):** 
  - Shows total allocated seats, category quotas, state quota vs All India Quota (AIQ) distributions for medical colleges.

---

## 4. Favourite Colleges (Bookmarks)

### 4.1 Add to Favourite
- **Endpoint:** `POST /api/student/favourite-colleges/` (`ApiEndpoints.addToFavourite`)
- **Service:** `FavouriteCollegeService.addToFavourite()` in `lib/services/favourite_college_service.dart`
- **Controller:** `FavouriteCollegeController` in `lib/Modules/favourite/controller/fevorite_collage_controller.dart`
- **WHERE (Screen):** 
  - `CollegeListPage` (Heart icon on card)
  - `CollegeDetailPage` (App bar bookmark button)
- **WHY (Purpose):** 
  - Adds a college to student's personal wishlist for quick access and counseling planning.

---

### 4.2 Remove from Favourite
- **Endpoint:** `POST /api/student/favourite-colleges/remove/` (`ApiEndpoints.removeFromFavourite`)
- **Service:** `FavouriteCollegeService.removeFromFavourite()` in `lib/services/favourite_college_service.dart`
- **Controller:** `FavouriteCollegeController` in `lib/Modules/favourite/controller/fevorite_collage_controller.dart`
- **WHERE (Screen):** 
  - `FavouriteCollegesPage` (`lib/Modules/favourite/view/favourite_colleges_page.dart`)
  - `CollegeListPage`, `CollegeDetailPage`
- **WHY (Purpose):** 
  - Removes a college from the student's favorites list.

---

### 4.3 List Favourite Colleges
- **Endpoint:** `GET /api/student/favourite-colleges/` (`ApiEndpoints.favourite`)
- **Service:** `FavouriteCollegeService.getFavouriteColleges()` in `lib/services/favourite_college_service.dart`
- **Controller:** `FavouriteCollegeController.fetchFavourites()`
- **WHERE (Screen):** 
  - `FavouriteCollegesPage` (`lib/Modules/favourite/view/favourite_colleges_page.dart`)
- **WHY (Purpose):** 
  - Fetches and displays all colleges saved/bookmarked by the user.

---

## 5. College Comparison

### 5.1 Compare Colleges
- **Endpoint:** `POST /api/colleges/compare/` (`ApiEndpoints.compareColleges`)
- **Service:** `CollegeCompareService.compareColleges()` in `lib/services/compare_collage_services.dart`
- **Controller:** `CollegeCompareController.compareColleges()` in `lib/Modules/comparison/controller/college_compare_controller.dart`
- **WHERE (Screen):** 
  - `CompareCollegesView` (`lib/Modules/comparison/view/compare_colleges_page.dart`)
- **WHY (Purpose):** 
  - Takes 2 to 4 college IDs and generates side-by-side comparative analytics (Cutoffs, Fees, Beds, Patient Flow, Establishment Year, Quotas).

---

### 5.2 Save Compare Colleges
- **Endpoint:** `POST /api/colleges/compare/save/` (`ApiEndpoints.saveCompareColleges`)
- **Service:** `SaveCompareService.saveCompare()` in `lib/services/save_compare_service.dart`
- **Controller:** `CollegeCompareController.saveComparison()`
- **WHERE (Screen):** 
  - `CompareCollegesView` (`lib/Modules/comparison/view/compare_colleges_page.dart`)
- **WHY (Purpose):** 
  - Saves a specific comparison session to cloud history so the student can re-examine it later.

---

### 5.3 Compare History
- **Endpoint:** `GET /api/colleges/compare/history/` (`ApiEndpoints.compareHistory`)
- **Service:** `CompareHistoryService.fetchHistory()` in `lib/services/compare_history_service.dart`
- **Controller:** `CompareHistoryController` in `lib/Modules/comparison/controller/compare_history_controller.dart`
- **WHERE (Screen):** 
  - `CompareHistoryView` (`lib/Modules/comparison/view/compare_history_save.dart`)
- **WHY (Purpose):** 
  - Displays list of previously saved college comparisons.

---

### 5.4 Delete Compare History
- **Endpoint:** `POST /api/colleges/compare/delete/` (`ApiEndpoints.deleteCompareHistory`)
- **Service:** `CompareHistoryService.deleteHistory()` in `lib/services/compare_history_service.dart`
- **Controller:** `CompareHistoryController.deleteComparison()`
- **WHERE (Screen):** 
  - `CompareHistoryView` (`lib/Modules/comparison/view/compare_history_save.dart`)
- **WHY (Purpose):** 
  - Deletes a saved comparison item from user history.

---

## 6. AI Rank Prediction & Cutoff Analysis

### 6.1 Predict Colleges
- **Endpoint:** `POST /api/prediction/` (`ApiEndpoints.predictCollege`)
- **Service:** `PredictionService.predictColleges()` in `lib/services/prediction_services.dart`
- **Controller:** `PredictionController.predictColleges()` in `lib/Modules/predication/controller/prediction_controller.dart`
- **WHERE (Screen):** 
  - `PredictionView` (`lib/Modules/predication/view/predication_view.dart`)
  - `AiPredictionResultView` (`lib/Modules/predication/view/ai_prediction_result_view.dart`)
  - `ChatBotPredictionView` (`lib/Modules/predication/view/chat_bot_prediction_view.dart`)
- **WHY (Purpose):** 
  - The flagship AI feature of the app. Takes the student's NEET Rank, Score, Category, Domicile State, and Course preferences, then predicts admission chances classified into High, Medium, and Low probability colleges.

---

### 6.2 State-wise Availability for Prediction
- **Endpoint:** `GET /api/prediction/statewise-availability/` (`ApiEndpoints.statewiseAvailability`)
- **Service:** `StateCategoryApiService.fetchStatewiseAvailability()` in `lib/services/state_category_service.dart`
- **Controller:** `PredictionController.fetchStatewiseAvailability()`
- **WHERE (Screen):** 
  - `PredictionView` (`lib/Modules/predication/view/predication_view.dart`)
- **WHY (Purpose):** 
  - Fetches list of states available for admission prediction based on student's current subscribed package.

---

### 6.3 Available Prediction Categories
- **Endpoint:** `GET /api/prediction/available-categories/` (`ApiEndpoints.availableCategories`)
- **Service:** `StateCategoryApiService.fetchAvailableCategories()` in `lib/services/state_category_service.dart`
- **Controller:** `PredictionController`
- **WHERE (Screen):** 
  - `PredictionView` dropdown filters
- **WHY (Purpose):** 
  - Dynamically retrieves valid counseling categories (General, OBC, SC, ST, EWS, Minority quotas) available for the selected state and quota.

---

### 6.4 NEET Rank Predictor
- **Endpoint:** `GET /api/neet-rank-predictor/?score={score}` (`ApiEndpoints.neetRankPredictor`)
- **Service:** `NeetRankService.predictRank()` in `lib/services/rank_predict_services.dart`
- **Controller:** `NeetRankController` in `lib/Modules/neet_rank/controller/neet_rank_controller.dart`, `RegisterController`
- **WHERE (Screen):** 
  - `NeetRankView` (`lib/Modules/neet_rank/view/neet_rank_view.dart`)
  - `RegisterPage` (`lib/Modules/register/view/register_page.dart`)
- **WHY (Purpose):** 
  - Estimates the student's expected All India NEET Rank from their test score/marks (out of 720) using historical score-vs-rank trends.

---

### 6.5 State-wise Rank Distribution
- **Endpoint:** `GET /api/state-wise-rank-distribution/` (`ApiEndpoints.stateWiseRankDistribution`)
- **Service:** `StateWiseDistributionService.fetchDistribution()` in `lib/services/state_wise_distribution_service.dart`
- **Controller:** `StateWiseDistributionController` in `lib/Modules/state_wise_distribution/controller/state_wise_distribution_controller.dart`
- **WHERE (Screen):** 
  - `StateWiseDistributionPage` (`lib/Modules/state_wise_distribution/view/state_wise_distribution_page.dart`)
- **WHY (Purpose):** 
  - Provides analytical graphs/charts showing rank ranges and candidate counts distribution across different Indian states.

---

### 6.6 Prediction Sheets
- **Endpoint:** `GET /api/student/prediction-sheets/` (`ApiEndpoints.predictionSheets`)
- **Service:** `PredictionSheetService.getPredictionSheets()` in `lib/services/predication_sheet_service.dart`
- **Controller:** `PredictionSheetController` in `lib/Modules/counselling_roadmap/controller/predication_sheet_controller.dart`
- **WHERE (Screen):** 
  - `CounsellingRoadmapScreen` (`lib/Modules/counselling_roadmap/view/counselling_roadmap_screen.dart`)
- **WHY (Purpose):** 
  - Fetches generated downloadable PDF counseling choice filling and preference sheets prepared for the student.

---

### 6.7 AIR Comparison
- **Endpoint:** `GET /api/air-comparison/` (`ApiEndpoints.airComparison`)
- **Service:** `AirComparisonApiService.getAirComparison()` in `lib/services/cutoff_services.dart`
- **Controller:** `CutoffController` in `lib/Modules/cutoff/controller/cotoff_controller.dart`
- **WHERE (Screen):** 
  - `CutoffPage` (`lib/Modules/cutoff/view/cutoff_page.dart`)
- **WHY (Purpose):** 
  - Compares year-over-year All India Rank cutoffs across counseling rounds for specific colleges.

---

### 6.8 Rank Analysis
- **Endpoint:** `POST /api/rank-analysis/college/` (`ApiEndpoints.rankAnalysis`)
- **Service:** `RankAnalysisApiService.getRankAnalysis()` in `lib/services/rank_analysis_services.dart`
- **Controller:** `RankAnalysisController` in `lib/Modules/rank_analysis/controller/rank_analysis_controller.dart`
- **WHERE (Screen):** 
  - `RankAnalysisView` (`lib/Modules/rank_analysis/view/rank_analysis_view.dart`)
- **WHY (Purpose):** 
  - Provides in-depth rank feasibility analysis for a target college based on student's merit.

---

## 7. Subscriptions & Payments

### 7.1 Subscription Plans
- **Endpoint:** `GET /subscription-plans/` (`ApiEndpoints.subscriptionPlans`)
- **Service:** `SubscriptionApi.fetchSubscriptionPlans()` in `lib/services/subscription_plan_services.dart`
- **Controller:** `SubscriptionController.fetchPlans()` in `lib/Modules/subscription/controller/subscription_controller.dart`
- **WHERE (Screen):** 
  - `SubscriptionPage` (`lib/Modules/subscription/view/subscription_plan_page.dart`)
- **WHY (Purpose):** 
  - Fetches pricing tiers, features (AI prediction, counselor call, roadmap, choice filling), and state limits.

---

### 7.2 Subscription Purchase
- **Endpoint:** `POST /api/subscription/purchase/` (`ApiEndpoints.subscriptionPurchase`)
- **Service:** `SubscriptionApi.purchaseSubscription()` in `lib/services/subscription_plan_services.dart`
- **Controller:** `SubscriptionController.purchasePlan()`
- **WHERE (Screen):** 
  - `SubscriptionPage` (`lib/Modules/subscription/view/subscription_plan_page.dart`)
- **WHY (Purpose):** 
  - Initiates package purchase request and registers intent with backend.

---

### 7.3 Create Subscription Order (Razorpay)
- **Endpoint:** `POST /api/student/subscription/create-order/` (`ApiEndpoints.subscriptionCreateOrder`)
- **Service:** `SubscriptionApi.createOrder()` in `lib/services/subscription_plan_services.dart`
- **Controller:** `SubscriptionController.createRazorpayOrder()`
- **WHERE (Screen):** 
  - `SubscriptionPage` checkout modal
- **WHY (Purpose):** 
  - Creates a Razorpay Order ID for initiating the online payment gateway SDK.

---

### 7.4 Verify Payment
- **Endpoint:** `POST /api/student/subscription/verify-payment/` (`ApiEndpoints.subscriptionVerifyPayment`)
- **Service:** `SubscriptionApi.verifyPayment()` in `lib/services/subscription_plan_services.dart`
- **Controller:** `SubscriptionController.verifyPayment()`
- **WHERE (Screen):** 
  - `SubscriptionPage` (called after Razorpay SDK success callback)
- **WHY (Purpose):** 
  - Submits Razorpay payment ID, order ID, and signature to backend for cryptographic verification and unlocks premium features.

---

### 7.5 Subscription History
- **Endpoint:** `GET /api/subscriptions/user/{userId}/` (`ApiEndpoints.subscriptionHistory`)
- **Service:** `SubscriptionApi.fetchSubscriptionHistory()` in `lib/services/subscription_plan_services.dart`
- **Controller:** `SubscriptionHistoryController` in `lib/Modules/subscription/controller/subsciption_history_controller.dart`
- **WHERE (Screen):** 
  - `MyPackagesPage` (`lib/Modules/subscription/view/my_packages_page.dart`)
  - `SubscriptionHistoryPage` (`lib/Modules/subscription/view/subscription_history_page.dart`)
- **WHY (Purpose):** 
  - Displays user's active and expired packages, transaction receipts, expiry dates, and enabled states/courses.

---

### 7.6 Student Subscription States (Get & Save)
- **Endpoint:** `GET` and `POST /api/student/subscription/states/` (`ApiEndpoints.subscriptionStates`)
- **Service:** `SubscriptionApi.getStatesWithoutSubscription()` & `saveSubscriptionStates()`
- **Controller:** `SubscriptionController`
- **WHERE (Screen):** 
  - `StateSelectionBottomSheet` inside Subscription & Prediction
- **WHY (Purpose):** 
  - **GET:** Returns which state counselings the student is eligible to choose or has already chosen.
  - **POST:** Saves state selections according to plan quota (e.g. 2 states or All-India).

---

### 7.7 Add Course & Add Specialty to Subscription
- **Endpoints:** 
  - `POST /api/student/subscription/add-course/` (`ApiEndpoints.subscriptionAddCourse`)
  - `POST /api/student/subscription/add-specialty/` (`ApiEndpoints.subscriptionAddSpecialty`)
  - `GET /api/student/subscription/available-courses/` (`ApiEndpoints.subscriptionAvailableCourses`)
  - `GET /api/student/subscription/specialties/` (`ApiEndpoints.subscriptionSpecialties`)
- **Service:** `SubscriptionApi` in `lib/services/subscription_plan_services.dart`
- **Controller:** `SubscriptionController`
- **WHERE (Screen):** 
  - `CourseSelectionBottomSheet` (`lib/Modules/subscription/widgets/course_selection_bottom_sheet.dart`)
- **WHY (Purpose):** 
  - Allows students to add/unlock specific medical courses (MBBS, BDS, BAMS, BHMS) or specialties under their active package.

---

### 7.8 Payment Credentials & App Verification
- **Endpoints:**
  - `GET /api/payment-credentials/` (`ApiEndpoints.paymentCredentials`)
  - `GET /api/app-verification/` (`ApiEndpoints.appVerification`)
- **Service:** `PaymentApiService.fetchPaymentCredentials()` & `isAppInReview()` in `lib/services/payment_services.dart`
- **Controller:** `AppVerificationController` in `lib/services/app_verification_controller.dart`
- **WHERE (Screen):** 
  - `HomePage`, `SubscriptionPage`, `SettingsPage`
- **WHY (Purpose):** 
  - Fetches the active Razorpay Key ID securely.
  - Checks if the app is currently under Apple App Store Review; if true, hides payment/purchase buttons to comply with App Store guideline 3.1.1.

---

## 8. Counselor & Guidance Assistance

### 8.1 Counselors List & Detail
- **Endpoints:** 
  - `GET /api/assistance/counselors/` (`ApiEndpoints.assistanceCounselors`)
  - `GET /api/assistance/counselor/{id}/` (`ApiEndpoints.counselorDetail`)
- **Service:** `CounselorService.fetchCounselors()` & `fetchCounselorDetail()` in `lib/services/counselor_services.dart`
- **Controller:** `CounselorController`, `CounselorDetailController`
- **WHERE (Screen):** 
  - `CounselorDetailsPage` (`lib/Modules/assistance/views/counselor_details_page.dart`)
- **WHY (Purpose):** 
  - Retrieves profiles of expert admission counselors (experience, ratings, languages, bio) available for 1-on-1 guidance.

---

### 8.2 Select Counselor
- **Endpoint:** `POST /api/assistance/select-counselor/` (`ApiEndpoints.selectCounselor`)
- **Service:** `CounselorService.selectCounselor()` in `lib/services/counselor_services.dart`
- **Controller:** `CounselorDetailController`
- **WHERE (Screen):** 
  - `CounselorDetailsPage`
- **WHY (Purpose):** 
  - Assigns a chosen counselor to the student's active counseling case.

---

### 8.3 Request Guidance (Book Session & History)
- **Endpoints:** 
  - `POST /api/request-guidance/` (`ApiEndpoints.requestGuidance`)
  - `GET /api/request-guidance/` (`ApiEndpoints.requestGuidance`)
  - `GET /api/request-guidance/{id}/` (`ApiEndpoints.requestGuidance`)
- **Service:** `RequestGuidanceService` in `lib/services/request_guidance_service.dart`
- **Controller:** `RequestGuidanceController`, `GuidanceRequestsController`
- **WHERE (Screen):** 
  - `RequestGuidanceView` (`lib/Modules/assistance/views/request_guidance_view.dart`)
  - `CounselorPage` (`lib/Modules/assistance/views/counselor_page.dart`)
- **WHY (Purpose):** 
  - Submits a request for a callback or 1-on-1 counseling appointment and tracks past consultation request statuses (Pending, Approved, Completed).

---

### 8.4 Add-on Counselor Contact
- **Endpoint:** `GET /api/get_addon_contact/` (`ApiEndpoints.addonContact`)
- **Service:** `AddonContactService.getAddonContact()` in `lib/services/addon_contact_service.dart`
- **Controller:** `AddonContactController` in `lib/Modules/counselling_roadmap/controller/addon_contact_controller.dart`
- **WHERE (Screen):** 
  - `CounsellingRoadmapScreen` (`lib/Modules/counselling_roadmap/view/counselling_roadmap_screen.dart`)
- **WHY (Purpose):** 
  - Fetches direct counselor phone/WhatsApp contact information provided as an add-on service.

---

## 9. Student Documents Management

### 9.1 Upload Document
- **Endpoint:** `POST /api/student/documents/upload/` (`ApiEndpoints.documents`)
- **Service:** `DocumentApiService.uploadDocument()` in `lib/services/document_api_services.dart`
- **Controller:** `DocumentController.uploadDocument()` in `lib/Modules/Documents/controller/documents_controller.dart`
- **WHERE (Screen):** 
  - `UploadDocumentPage` (`lib/Modules/Documents/view/documents_view.dart`)
- **WHY (Purpose):** 
  - Multi-part file upload for required verification certificates (NEET Admit Card, Scorecard, 10th/12th Marksheets, Domicile, Category Certificate).

---

### 9.2 Update Document
- **Endpoint:** `POST /api/student/documents/update/` (`ApiEndpoints.updateStudentDocument`)
- **Service:** `DocumentApiService.updateDocument()` in `lib/services/document_api_services.dart`
- **Controller:** `DocumentController`
- **WHERE (Screen):** 
  - `StudentDocumentsUnifiedPage` (`lib/Modules/Documents/view/update_doc_page.dart`)
- **WHY (Purpose):** 
  - Replaces an existing uploaded document with a corrected or clearer file scan.

---

### 9.3 Get Student Documents List
- **Endpoint:** `GET /api/student/documents/` (`ApiEndpoints.studentDocuments`)
- **Service:** `StudentDocumentService.getDocuments()` in `lib/services/view_document_service.dart`
- **Controller:** `StudentDocumentsController` in `lib/Modules/Documents/controller/view_document_controller.dart`
- **WHERE (Screen):** 
  - `DocumentsGalleryPage` (`lib/Modules/Documents/view/view_documents_page.dart`)
- **WHY (Purpose):** 
  - Displays all uploaded certificates, verification statuses (Verified, Pending, Rejected), and preview URLs.

---

## 10. Chatbot & Admission Chat Support

### 10.1 Start Chat & Admission Chat
- **Endpoints:** 
  - `POST /api/chat/start/` (`ApiEndpoints.chatStart`)
  - `POST /api/chat/admission/` (`ApiEndpoints.chatAdmission`)
- **Service:** `ChatApi.startChat()` & `admissionStart()` in `lib/services/chat_services.dart`
- **Controller:** `ChatController` in `lib/Modules/Chatbot/controller/chatbot_controller.dart`
- **WHERE (Screen):** 
  - `ChatView` (`lib/Modules/Chatbot/view/chatbot_view.dart`)
  - `AdmissionChatView` (`lib/Modules/Chatbot/view/admission_chat_view.dart`)
- **WHY (Purpose):** 
  - Initializes a new interactive chat session (either general bot or specialized admission inquiry) and receives initial greetings and suggestions.

---

### 10.2 Bot Response & Send Message
- **Endpoints:** 
  - `POST /api/chat/bot-response/` (`ApiEndpoints.chatBotResponse`)
  - `POST /api/chat/message/` (`ApiEndpoints.chatMessage`)
- **Service:** `ChatApi.botResponse()` & `sendMessage()` in `lib/services/chat_services.dart`
- **Controller:** `ChatController.sendMessage()`
- **WHERE (Screen):** 
  - `ChatView`, `AdmissionChatView`
- **WHY (Purpose):** 
  - Sends user queries, triggers automated bot AI answers regarding cutoffs, colleges, counseling dates, and eligibility.

---

### 10.3 Switch to Human Counselor
- **Endpoint:** `POST /api/chat/switch-to-human/` (`ApiEndpoints.chatSwitchToHuman`)
- **Service:** `ChatApi.switchToHuman()` in `lib/services/chat_services.dart`
- **Controller:** `ChatController.switchToHuman()`
- **WHERE (Screen):** 
  - `ChatView`, `AdmissionChatView`
- **WHY (Purpose):** 
  - Transfers the active chat from automated AI bot to a live human counselor for complex queries.

---

### 10.4 Chat History, Messages, Clear & Close
- **Endpoints:** 
  - `GET /api/chat/messages/?session_id=...` (`ApiEndpoints.chatMessages`)
  - `GET /api/chat/history/?session_id=...` (`ApiEndpoints.chatHistory`)
  - `GET /api/chat/sessions/?entry_flow=...` (`ApiEndpoints.chatSessions`)
  - `POST /api/chat/clear/` (`ApiEndpoints.chatClear`)
  - `POST /api/chat/close/` (`ApiEndpoints.chatClose`)
- **Service:** `ChatApi` in `lib/services/chat_services.dart`
- **Controller:** `ChatController`
- **WHERE (Screen):** 
  - `ChatView`, `AdmissionChatView`
- **WHY (Purpose):** 
  - Fetches historical message logs, pagination, clears active thread, or marks counseling chat as closed.

---

## 11. Notifications & Alerts

### 11.1 Public Alerts & News Feed
- **Endpoint:** `GET /alert/api/notifications/?page={page}` (`ApiEndpoints.alerts`)
- **Service:** `NotificationApiService.fetchNotifications()` in `lib/services/appnotification_services.dart`
- **Controller:** `AlertsController` in `lib/Modules/notification/controller/alerts_controller.dart`
- **WHERE (Screen):** 
  - `AlertsPage` (`lib/Modules/notification/veiw/alerts_page.dart`)
- **WHY (Purpose):** 
  - Displays official state and MCC counseling circulars, dates, exam notifications, and news alerts.

---

### 11.2 Student Personal Notifications
- **Endpoint:** `GET /api/student/notifications/` (`ApiEndpoints.studentNotifications`)
- **Service:** `StudentNotificationService.fetchNotifications()` in `lib/services/student_notification_service.dart`
- **Controller:** `NotificationController` in `lib/Modules/notification/controller/notification_controller.dart`
- **WHERE (Screen):** 
  - `NotificationPage` (`lib/Modules/notification/veiw/notification_page.dart`)
  - `HomePage` (Notification Bell icon count)
- **WHY (Purpose):** 
  - Retrieves personal user notifications (e.g. document verification status, payment success, counselor replies).

---

### 11.3 Notification Actions (Mark Read & Delete)
- **Endpoints:**
  - `POST /api/notifications/{id}/mark-read/` (`ApiEndpoints.markNotificationRead`)
  - `POST /api/notifications/mark-all-read/` (`ApiEndpoints.markAllNotificationsRead`)
  - `DELETE/POST /api/notifications/{id}/delete/` (`ApiEndpoints.deleteNotification`)
  - `DELETE/POST /api/notifications/delete-all/` (`ApiEndpoints.deleteAllNotifications`)
  - `DELETE/POST /api/notifications/delete-read/` (`ApiEndpoints.deleteReadNotifications`)
- **Service:** `NotificationActionService` in `lib/services/notification_action_service.dart`
- **Controller:** `AlertsController`, `NotificationController`
- **WHERE (Screen):** 
  - `NotificationPage`, `AlertsPage`
- **WHY (Purpose):** 
  - Allows students to manage their notification feed: mark individual or all notifications as read, and delete unwanted alerts.

---

### 11.4 Notification Settings (Get & Put)
- **Endpoint:** `GET` and `PUT /api/user/notification-settings/` (`ApiEndpoints.notificationSettings`)
- **Service:** `NotificationApiService.fetchNotificationSettings()` & `updateNotificationSettings()` in `lib/services/appnotification_services.dart`
- **Controller:** `NotificationController`
- **WHERE (Screen):** 
  - `NotificationSettingsScreen` (`lib/Modules/settings/view/notification_settings_page.dart`)
- **WHY (Purpose):** 
  - Allows users to toggle push notification preferences (Counseling updates, App alerts, Promotional messages).

---

## 12. Support & Helpdesk Tickets

### 12.1 Create Support Ticket
- **Endpoint:** `POST /api/tickets/create/` (`ApiEndpoints.createTicket`)
- **Service:** `TicketService.createTicket()` in `lib/services/ticket_services.dart`
- **Controller:** `TicketController.createTicket()` in `lib/Modules/ticket/controller/ticket_controller.dart`
- **WHERE (Screen):** 
  - `CreateTicketView` (`lib/Modules/ticket/view/ticket_view.dart`)
- **WHY (Purpose):** 
  - Enables students to submit complaints or queries regarding payments, prediction sheets, or counselors along with screenshot attachments.

---

### 12.2 Get User Tickets & Ticket Thread
- **Endpoints:** 
  - `GET /api/tickets/` (`ApiEndpoints.getTickets`)
  - `GET /api/tickets/{id}/` (`ApiEndpoints.getTickets`)
- **Service:** `TicketService.getTickets()` & `getTicketDetails()` in `lib/services/ticket_services.dart`
- **Controller:** `TicketController` in `lib/Modules/ticket/controller/ticket_controller.dart`
- **WHERE (Screen):** 
  - `CreateTicketView` -> Ticket List tab / Ticket detail dialog
- **WHY (Purpose):** 
  - Lists student's raised tickets with status (Open, In-Progress, Resolved) and displays entire conversation thread with admin.

---

### 12.3 Reply to Support Ticket
- **Endpoint:** `POST /api/tickets/reply/` (`ApiEndpoints.ticketReply`)
- **Service:** `TicketService.replyTicket()` in `lib/services/ticket_services.dart`
- **Controller:** `TicketController.replyTicket()`
- **WHERE (Screen):** 
  - `CreateTicketView` -> Ticket conversation thread
- **WHY (Purpose):** 
  - Sends follow-up student messages and attachments inside an existing support ticket.

---

### 12.4 Support Contact Info
- **Endpoint:** `GET /api/support/contact/` (`ApiEndpoints.supportContact`)
- **Service:** `SupportService.getSupportContact()` in `lib/services/support_service.dart`
- **Controller:** `SupportController` in `lib/Modules/support/controller/support_controller.dart`
- **WHERE (Screen):** 
  - `SupportPage` (`lib/Modules/support/view/support_page.dart`)
  - `AboutPage` (`lib/Modules/settings/view/about_page.dart`)
- **WHY (Purpose):** 
  - Displays company helpline numbers, official support email, WhatsApp assistance link, and address.

---

### 12.5 FAQs
- **Endpoint:** `GET /api/faqs/` (`ApiEndpoints.faq`)
- **Service:** `FaqApiService.getFaqs()` in `lib/services/faq_api_service.dart`
- **Controller:** `FaqController` in `lib/Modules/Home/controller/faq_controller.dart`
- **WHERE (Screen):** 
  - `HomePage` (`lib/Modules/Home/Veiw/home_page.dart`)
- **WHY (Purpose):** 
  - Loads Frequently Asked Questions and answers about NEET counseling rules, domicile requirements, and app features.
