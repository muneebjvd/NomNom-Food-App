 **NomNom** is a full-stack mobile food delivery application built with **Flutter** (Dart), featuring a TikTok-style video feed for discovering food, real-time order tracking, and dual-role access for customers and restaurant owners.


### Key Features

- **TikTok-style Feed** — Vertical swipe-based dish discovery with video previews, double-tap likes, and haptic feedback

- **Dual-Role System** — Separate dashboards for Customers and Restaurant Owners with role-based routing

- **Order Management** — Real-time order status tracking with live courier simulation on Google Maps

- **Cart & Checkout** — Multi-item cart with promo code support, mock Stripe card integration, and price breakdown

- **Owner Panel** — Full admin dashboard to add/edit menu items, manage orders, and view analytics

- **Address Management** — Multiple saved addresses per customer with Google Maps pin-drop picker

- **Persistent Storage** — All data (users, cart, dishes) persists across app restarts via `shared_preferences`

- **Reviews & Ratings** — Star ratings on dish detail screens with customer review display

- **Push Notification Simulation** — In-app order status change notifications


### Tech Stack

| Layer | Technology |

|-------|-----------|

| Framework | Flutter (Dart) |

| State Management | Riverpod |

| Navigation | GoRouter |

| Backend | Firebase (Auth + Firestore) |

| Local Storage | SharedPreferences |

| Maps | Google Maps Flutter |

| UI | Custom design system, Google Fonts, Iconly |


### Market Focus

Localized for the **Pakistani market** — PKR currency (Rs.), Pakistani dishes, Lahore-based coordinates, and culturally relevant naming throughout. 
