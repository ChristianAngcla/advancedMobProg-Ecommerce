-- Lab Activity 2: Discussion -- 

How the Model, Service, and Screen Work Together
- In this activity, the product data is retrieved from an API. Each part of the project has its own responsibility to keep the code organized.

1. constants.dart reads the HOST value from the .env file, which serves as the base URL of the API.
2. ProductService sends an HTTP GET request to the /products endpoint. If the request is successful, it converts the JSON response into a list of product objects.
3. Product defines the structure of each product. The fromJson() method converts the raw JSON data into Dart objects, including nested objects such as dimensions and reviews.
4. ProductScreen requests the data when the screen loads by calling the service inside initState(). A FutureBuilder is then used to display a loading indicator, an error message, or the list of products.
5. When a product card is tapped, ProductScreen passes that Product object to ProductDetailScreen so the details page can show more information.

- Overall, the flow of data is: API → Service → Model → Screen
This structure keeps the code organized because each part has its own responsibility.

-- Design Pattern Used -- 
This project follows a layered architecture.

1. models/ contains the data models and JSON conversion.
2. services/ handles API requests.
3. screens/ contains the user interface.
4. widgets/ stores reusable UI components.
5. providers/ manages application state, such as the app theme.

The project also uses the Provider package for state management. ThemeProvider stores the current theme, and whenever toggleTheme() is called, notifyListeners() automatically updates the user interface.

-- Enhancements -- 
Enhancement 1: Added a search bar that filters products by title.
Enhancement 2: Added a details page. Tapping a product card opens ProductDetailScreen with the selected product’s image, title, price, and description.
Enhancement 3: Added a settings page with a dark/light mode toggle using Provider.


-- Lab Activity 3: Discussion -- 

How the Cart Model, Service, and Screen Work Together
- Cart data comes from the DummyJSON API (/carts/user/{id} and /carts/add).

1. CartService calls the cart API endpoints.
2. Cart and CartProduct models convert the JSON into Dart objects using fromJson().
3. CartProvider loads the cart once, then keeps it in memory. Add, plus, minus, and remove update this shared list so changes stay when switching tabs.
4. CartScreen shows the items, quantity controls, and a price breakdown (Total, Discount, Total Discount) in pesos (₱).
5. Tapping a cart item opens ProductDetailScreen without the Add to Cart button.
6. Confirm Order shows a confirmation dialog before placing the order.

- Flow: API → CartService → Cart model → CartProvider → CartScreen

Design Pattern
- Same layered folders as Lab 2 (models, services, screens, providers).
- CartProvider stores shared cart state for the whole app (DummyJSON add does not save permanently, so local state is needed).
- HomeScreen hides the Chat FAB on the Cart tab. Tapping Chat opens a basic bottom sheet chat UI.

Why getById / user cart
- GET /carts/user/{id} loads only one user’s cart instead of all carts, so the app shows the correct cart faster.

-- Enhancements -- 
Enhancement 1: CartScreen shows cart products from the API. Tapping an item opens ProductDetailScreen (no Add to Cart). Minus removes the item at quantity 0. Price breakdown and Confirm Order dialog are included.
Enhancement 2: Chat is a FloatingActionButton (hidden on Cart). It opens a bottom sheet chat screen.
Enhancement 3: Load cart by user ID and Add to Cart with POST /carts/add, then update CartProvider so new items appear in the cart.


-- Lab Activity 4: Discussion --

How the User Model, Services, and Screen Interact
- In Lab Activity 4, user authentication and persistent sessions are integrated with DummyJSON (/auth/login).
1. When a user submits their credentials on SignInScreen, UserService.loginUser() sends an HTTP POST request to /auth/login.
2. Upon receiving the API response, UserService.saveUserData() parses the data with User.fromJson() and writes all fields (id, username, email, firstName, lastName, gender, image, accessToken) into SharedPreferences.
3. On ProfileScreen, initState() calls UserService.getUser().
4. UserService reads the stored session map from SharedPreferences and deserializes it into a strongly-typed User object using User.fromJson().
5. ProfileScreen uses a FutureBuilder<User> to render the user's avatar, name, email, gender, and ID into styled cards without requiring extra internet calls.

Updated Design Pattern
- The architecture expands into a Persistent Authentication & Session-Driven Layered Architecture:
  - Storage Layer (SharedPreferences): Functions as local device storage preserving user tokens and identity across app restarts.
  - Lifecycle Gatekeeper (SplashScreen): Automatically inspects SharedPreferences on boot (isLoggedIn()) to determine whether to route to /home or /signin.
  - Cross-Feature Context Sharing: Authenticated user credentials dynamically feed into other feature modules (e.g. driving user-specific cart queries).

Utilizing Saved Data in Rendering CartScreen by User ID
- In Lab 3, cart data was fetched using a hardcoded user ID.
- In Lab 4, CartScreen queries UserService.getUser() during initialization to extract the logged-in user's true ID.
- It passes this saved ID into CartProvider.loadCart(userId), which calls CartService.getUserCart(userId) (GET /carts/user/{id}).
- This guarantees that whichever user logs in, the app automatically loads and displays their personal shopping cart.

-- Enhancements Implemented in Lab Activity 4 --
Enhancement 1: Built custom SplashScreen UI with NUBD Exchange branding, fade animation, and persistent authentication logic routing to /home or /signin.
Enhancement 2: Built custom SignInScreen UI with form validation, password visibility eye toggle, and UserService.loginUser() authentication.
Enhancement 3: Created User model (user.dart), rendered user profile on ProfileScreen, and dynamically rendered CartScreen based on the saved userId.
Confirmation Modal Enhancement: Created a Material 3 order summary modal bottom sheet on CartScreen and a confirmation alert dialog before logging out on ProfileScreen.
Performance Enhancement: Implemented infinite scroll pagination with limit and skip query parameters on ProductScreen to eliminate lag and loading delays.
Error Handling Enhancement: Implemented friendly error and empty states with retry action buttons across product and cart screens.

## Lab Activity 5: Discussion

This activity added Firebase Authentication while keeping the previous DummyJSON login. In the normal sign-in form, a username is handled by DummyJSON through its login API, while an email address is handled by Firebase. New users create a Firebase account by entering their personal details, email address, and password. After a successful sign-in, the app opens the same home screen and shows the correct profile details based on the account type.

UserService is the central file that handles the login, signup, logout, username update, password change, and account deletion actions. It also keeps the active session so the Splash Screen can decide whether to open Home or Sign In. Firebase stores the account credentials, while the extra registration details needed by this laboratory are kept locally on the same device without saving passwords or authentication tokens.

Firebase improves the application by providing real email and password authentication instead of relying only on DummyJSON demo users. It allows account creation, secure sign-in, password changes, account deletion, and logout. The existing DummyJSON flow was retained so the earlier laboratory features continue to work.

## Lab Activity 6: Discussion

Lab Activity 6 added Cloud Firestore for direct messaging between Firebase users. When a Firebase user signs up or signs in, UserService saves safe profile details in the `users` collection. The Chat screen displays other registered users, supports searching by name, username, or email, and opens a one-to-one conversation. Each pair uses one sorted chat-room ID, so both users access the same message history.

ChatService saves and streams messages from Firestore, allowing conversations to update automatically. The chat list shows the latest message and unread count. Opening a chat marks incoming messages as read; one check means a message was saved, while double checks mean the receiver opened the conversation. NU Connect follows the project’s blue and gold design and includes clear loading, empty, and error states.
