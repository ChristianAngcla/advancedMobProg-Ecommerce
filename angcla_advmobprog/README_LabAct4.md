# Lab Activity 4: Discussion

## 1. How the User Model, Services, and Screen Interact
In Lab Activity 4, user authentication and persistent sessions are integrated with the DummyJSON API (`/auth/login`). Each component has a specific responsibility:

1. **`UserService` (Service Layer):** When a user submits their credentials on `SignInScreen`, `UserService.loginUser()` sends an HTTP POST request to `/auth/login`.
2. **Data Persistence (`SharedPreferences`):** Upon receiving the API response, `UserService.saveUserData()` parses the data with `User.fromJson()` and writes all fields (`id`, `username`, `email`, `firstName`, `lastName`, `gender`, `image`, `accessToken`) into `SharedPreferences`.
3. **`ProfileScreen` (UI Layer):** `initState()` calls `UserService.getUser()`.
4. **`User` Model (Data Layer):** `UserService` reads the stored session map from `SharedPreferences` and deserializes it into a strongly-typed `User` object using `User.fromJson()`.
5. **UI Rendering:** `ProfileScreen` uses a `FutureBuilder<User>` to render the user's avatar, name, email, gender, and ID into styled cards without requiring extra internet calls.

---

## 2. Updated Design Pattern
The architecture expands into a **Persistent Authentication & Session-Driven Layered Architecture**:

- **Storage Layer (`SharedPreferences`):** Functions as local device storage preserving user tokens and identity across app restarts.
- **Lifecycle Gatekeeper (`SplashScreen`):** Automatically inspects `SharedPreferences` on boot (`isLoggedIn()`) to determine whether to route to `/home` or `/signin`.
- **Cross-Feature Context Sharing:** Authenticated user credentials dynamically feed into other feature modules (e.g. driving user-specific cart queries).

---

## 3. Utilizing Saved Data in Rendering CartScreen by User ID
- In Lab 3, cart data was fetched using a hardcoded user ID.
- In Lab 4, `CartScreen` queries `UserService.getUser()` during initialization to extract the logged-in user's true ID.
- It passes this saved ID into `CartProvider.loadCart(userId)`, which calls `CartService.getUserCart(userId)` (`GET /carts/user/{id}`).
- This guarantees that whichever user logs in, the app automatically loads and displays their personal shopping cart.

---

## 4. Enhancements Implemented in Lab Activity 4
- **Enhancement 1:** Built custom `SplashScreen` UI with NUBD Exchange branding, fade animation, and persistent authentication logic routing to `/home` or `/signin`.
- **Enhancement 2:** Built custom `SignInScreen` UI with form validation, password visibility eye toggle, and `UserService.loginUser()` authentication.
- **Enhancement 3:** Created `User` model (`user.dart`), rendered user profile on `ProfileScreen`, and dynamically rendered `CartScreen` based on the saved `userId`.
- **Confirmation Modal Enhancement:** Created a Material 3 order summary modal bottom sheet on `CartScreen` and a confirmation alert dialog before logging out on `ProfileScreen`.
- **Performance Enhancement:** Implemented infinite scroll pagination with `limit` and `skip` query parameters on `ProductScreen` to eliminate lag and loading delays.
- **Error Handling Enhancement:** Implemented friendly error and empty states with retry action buttons across product and cart screens.
