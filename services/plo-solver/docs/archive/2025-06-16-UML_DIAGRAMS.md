# PLOSolver UML and Architecture Diagrams

This document contains all the UML and architecture diagrams for the PLOSolver application. These diagrams provide visual representations of the system architecture, component relationships, data flow, and deployment infrastructure.

## Table of Contents

1. [System Architecture Overview](#system-architecture-overview)
2. [Database Schema (ERD)](#database-schema-erd)
3. [React Component Hierarchy](#react-component-hierarchy)
4. [Backend API Structure](#backend-api-structure)
5. [Deployment Infrastructure](#deployment-infrastructure)
6. [Authentication Flow](#authentication-flow)

---

## System Architecture Overview

High-level overview of the entire PLOSolver system showing all major components and their relationships.

```mermaid
graph TB
    subgraph "Client Layer"
        Browser[Browser/User Interface]
        Mobile[Mobile App<br/>Future Extension]
    end
    
    subgraph "Load Balancer/Proxy"
        Traefik[Traefik Reverse Proxy<br/>- SSL Termination<br/>- Load Balancing<br/>- Service Discovery]
    end
    
    subgraph "Frontend Services"
        React[React SPA<br/>- Component-based UI<br/>- State Management<br/>- Routing<br/>- Authentication]
        WebPack[Webpack Dev Server<br/>- Hot Reload<br/>- Asset Bundling]
    end
    
    subgraph "Backend Services"
        Flask[Flask API Server<br/>- REST API<br/>- Authentication<br/>- Business Logic<br/>- Equity Calculations]
        
        subgraph "Core Modules"
            Auth[Authentication Module<br/>- JWT Tokens<br/>- OAuth Integration<br/>- Session Management]
            Equity[Equity Calculator<br/>- PLO Simulations<br/>- Multiprocessing<br/>- Hand Evaluation]
            Spots[Spot Management<br/>- Save/Load Spots<br/>- User Spots<br/>- Simulation Results]
            Profiles[Player Profiles<br/>- Predefined Profiles<br/>- Custom Profiles<br/>- Behavioral Modeling]
            Subscription[Subscription Service<br/>- Stripe Integration<br/>- Tier Management<br/>- Payment Processing]
        end
    end
    
    subgraph "External Services"
        Google[Google OAuth<br/>- User Authentication<br/>- Profile Data]
        Stripe[Stripe Payment<br/>- Subscription Management<br/>- Payment Processing]
        Forum[Discourse Forum<br/>- Community Discussion<br/>- SSO Integration]
    end
    
    subgraph "Data Layer"
        PostgreSQL[PostgreSQL Database<br/>- User Data<br/>- Spots<br/>- Sessions<br/>- Subscriptions]
        FileSystem[File System<br/>- Custom Profiles<br/>- Logs<br/>- Static Assets]
    end
    
    subgraph "Infrastructure"
        Docker[Docker Containers<br/>- Service Isolation<br/>- Environment Management<br/>- Scalability]
        Nginx[Nginx<br/>- Static File Serving<br/>- Reverse Proxy]
    end
    
    %% Client connections
    Browser --> Traefik
    Mobile --> Traefik
    
    %% Traefik routing
    Traefik --> React
    Traefik --> Flask
    Traefik --> Forum
    
    %% Frontend to Backend
    React --> Flask
    
    %% Backend module relationships
    Flask --> Auth
    Flask --> Equity
    Flask --> Spots
    Flask --> Profiles
    Flask --> Subscription
    
    %% External service connections
    Auth --> Google
    Subscription --> Stripe
    Flask --> Forum
    
    %% Data layer connections
    Auth --> PostgreSQL
    Spots --> PostgreSQL
    Subscription --> PostgreSQL
    Profiles --> FileSystem
    
    %% Infrastructure
    Docker --> Flask
    Docker --> React
    Docker --> PostgreSQL
    Docker --> Forum
    
    classDef frontend fill:#e1f5fe
    classDef backend fill:#f3e5f5
    classDef database fill:#e8f5e8
    classDef external fill:#fff3e0
    classDef infrastructure fill:#fafafa
    
    class React,WebPack,Browser,Mobile frontend
    class Flask,Auth,Equity,Spots,Profiles,Subscription backend
    class PostgreSQL,FileSystem database
    class Google,Stripe,Forum external
    class Traefik,Docker,Nginx infrastructure
```

---

## Database Schema (ERD)

Entity Relationship Diagram showing the database structure and relationships between tables.

```mermaid
erDiagram
    USERS {
        string id PK
        string email UK
        string username UK
        string password_hash
        string first_name
        string last_name
        string google_id UK
        string facebook_id UK
        string profile_picture
        boolean is_active
        boolean email_verified
        string subscription_tier
        string stripe_customer_id
        string stripe_subscription_id
        string subscription_status
        datetime subscription_current_period_end
        boolean subscription_cancel_at_period_end
        datetime created_at
        datetime updated_at
        datetime last_login
    }
    
    USER_SESSIONS {
        string id PK
        string user_id FK
        string token_jti UK
        string ip_address
        string user_agent
        datetime created_at
        datetime expires_at
        boolean is_active
    }
    
    SPOTS {
        string id PK
        string user_id FK
        string name
        text description
        json top_board
        json bottom_board
        json players
        integer simulation_runs
        integer max_hand_combinations
        json results
        datetime created_at
        datetime updated_at
    }
    
    USERS ||--o{ USER_SESSIONS : "has many sessions"
    USERS ||--o{ SPOTS : "owns many spots"
```

---

## React Component Hierarchy

Component structure and relationships in the React frontend application.

```mermaid
graph TD
    subgraph "Root Application"
        App[App Component<br/>- Router Configuration<br/>- Route Management]
        
        subgraph "Context Providers"
            ThemeProvider[ThemeProvider<br/>- Dark/Light Mode<br/>- Theme State]
            AuthProvider[AuthProvider<br/>- User Authentication<br/>- JWT Token Management<br/>- Login/Logout State]
            GoogleProvider[GoogleOAuthProvider<br/>- Google OAuth Integration]
        end
        
        subgraph "Page Components"
            LandingPage[LandingPage<br/>- Home Page<br/>- Feature Overview<br/>- Hero Section]
            PricingPage[PricingPage<br/>- Subscription Plans<br/>- Pricing Tiers<br/>- Feature Comparison]
            AppWrapper[AppWrapper<br/>- Main Application Shell<br/>- Navigation<br/>- Mode Management]
            Checkout[Checkout<br/>- Payment Processing<br/>- Stripe Integration]
            CheckoutSuccess[CheckoutSuccess<br/>- Payment Confirmation<br/>- Success Message]
        end
        
        subgraph "Application Modes"
            LiveMode[Live Mode<br/>- Real-time Poker Play<br/>- Interactive Game Board<br/>- Player Actions]
            SpotMode[SpotMode<br/>- Scenario Analysis<br/>- Spot Saving/Loading<br/>- Equity Calculations]
            TrainingMode[TrainingMode<br/>- AI Training<br/>- Opponent Modeling<br/>- Skill Development]
            PlayerProfiles[PlayerProfiles<br/>- Profile Management<br/>- Custom Profiles<br/>- Behavioral Settings]
            Forum[Forum<br/>- Community Discussion<br/>- Discourse Integration]
        end
        
        subgraph "Core Game Components"
            GameBoard[GameBoard<br/>- Card Display<br/>- Board State<br/>- Visual Layout]
            Player[Player<br/>- Player State<br/>- Hand Cards<br/>- Actions]
            Card[Card<br/>- Card Rendering<br/>- Suit/Rank Display]
            ActionButtons[ActionButtons<br/>- Player Actions<br/>- Bet/Call/Fold<br/>- Input Handling]
        end
        
        subgraph "Authentication Components"
            AuthModal[AuthModal<br/>- Login/Register Modal<br/>- Form Switching]
            Login[Login<br/>- Login Form<br/>- OAuth Integration]
            Register[Register<br/>- Registration Form<br/>- Validation]
        end
        
        subgraph "Utility Components"
            ThemeToggle[ThemeToggle<br/>- Theme Switcher<br/>- UI Control]
            TierIndicator[TierIndicator<br/>- Subscription Status<br/>- Tier Display]
            SavedSpots[SavedSpots<br/>- Spot History<br/>- Load/Delete Operations]
        end
        
        subgraph "Analytics & Features"
            EquityCalculator[EquityCalculatorWithAnalytics<br/>- Equity Calculations<br/>- Analytics Integration<br/>- Performance Tracking]
            AnalyticsExample[AnalyticsIntegrationExample<br/>- Usage Analytics<br/>- Event Tracking]
            DocumentationDashboard[DocumentationDashboard<br/>- API Documentation<br/>- Feature Guides]
        end
    end
    
    %% Root relationships
    App --> ThemeProvider
    App --> AuthProvider
    App --> GoogleProvider
    
    %% Page routing
    App --> LandingPage
    App --> PricingPage
    App --> AppWrapper
    App --> Checkout
    App --> CheckoutSuccess
    
    %% AppWrapper contains modes
    AppWrapper --> LiveMode
    AppWrapper --> SpotMode
    AppWrapper --> TrainingMode
    AppWrapper --> PlayerProfiles
    AppWrapper --> Forum
    
    %% Live mode components
    LiveMode --> GameBoard
    LiveMode --> Player
    LiveMode --> ActionButtons
    
    %% Spot mode components
    SpotMode --> GameBoard
    SpotMode --> Player
    SpotMode --> SavedSpots
    SpotMode --> EquityCalculator
    
    %% Training mode components
    TrainingMode --> GameBoard
    TrainingMode --> Player
    TrainingMode --> AnalyticsExample
    
    %% Shared components
    GameBoard --> Card
    Player --> Card
    
    %% Authentication flow
    AppWrapper --> AuthModal
    AuthModal --> Login
    AuthModal --> Register
    
    %% Utility components
    AppWrapper --> ThemeToggle
    AppWrapper --> TierIndicator
    
    %% Documentation
    AppWrapper --> DocumentationDashboard
    
    classDef page fill:#e3f2fd
    classDef context fill:#f3e5f5
    classDef mode fill:#e8f5e8
    classDef component fill:#fff3e0
    classDef auth fill:#fce4ec
    classDef utility fill:#f1f8e9
    
    class LandingPage,PricingPage,AppWrapper,Checkout,CheckoutSuccess page
    class ThemeProvider,AuthProvider,GoogleProvider context
    class LiveMode,SpotMode,TrainingMode,PlayerProfiles,Forum mode
    class GameBoard,Player,Card,ActionButtons component
    class AuthModal,Login,Register auth
    class ThemeToggle,TierIndicator,SavedSpots,EquityCalculator,AnalyticsExample,DocumentationDashboard utility
```

---

## Backend API Structure

Flask backend architecture showing routes, services, and data flow.

```mermaid
graph TB
    subgraph "Flask Application Server"
        FlaskApp[Flask App<br/>equity_server.py<br/>- Configuration<br/>- CORS Setup<br/>- JWT Management<br/>- Blueprint Registration]
        
        subgraph "Authentication System"
            AuthRoutes[Authentication Routes<br/>/auth/*<br/>- User Registration<br/>- Login/Logout<br/>- JWT Token Management<br/>- OAuth Integration]
            AuthUtils[Authentication Utilities<br/>- Token Validation<br/>- Password Hashing<br/>- OAuth Verification<br/>- Session Management]
        end
        
        subgraph "Core Business Logic"
            EquityEngine[Equity Calculation Engine<br/>- PLO Hand Evaluation<br/>- Monte Carlo Simulation<br/>- Multiprocessing<br/>- Hand Strength Analysis]
            
            SpotRoutes[Spot Management Routes<br/>/spots/*<br/>- Save/Load Spots<br/>- CRUD Operations<br/>- User Authorization<br/>- Result Storage]
            
            ProfileSystem[Player Profile System<br/>- Predefined Profiles<br/>- Custom Profile Creation<br/>- Behavioral Modeling<br/>- Profile Management]
        end
        
        subgraph "Business Features"
            SubscriptionRoutes[Subscription Routes<br/>/api/subscription/*<br/>- Stripe Integration<br/>- Plan Management<br/>- Payment Processing<br/>- Tier Validation]
            
            DocsRoutes[Documentation Routes<br/>/docs/*<br/>- API Documentation<br/>- Interactive Docs<br/>- Feature Guides]
            
            ForumRoutes[Forum Integration Routes<br/>/discourse/*<br/>- SSO Provider<br/>- User Sync<br/>- Forum Authentication<br/>- Community Features]
        end
        
        subgraph "Core Endpoints"
            HealthCheck[Health Check<br/>/health<br/>- System Status<br/>- Connectivity Test<br/>- Service Monitoring]
            
            EquityAPI[Equity Calculation API<br/>/simulated-equity<br/>- Hand vs Hand<br/>- Board Analysis<br/>- Probability Calculations]
            
            SpotSimulation[Spot Simulation API<br/>/spot-simulation<br/>- Multi-player Analysis<br/>- Scenario Modeling<br/>- Advanced Calculations]
            
            ProfileAPI[Player Profile API<br/>/api/player-profiles<br/>- Profile CRUD<br/>- Custom Profiles<br/>- Behavioral Settings]
            
            ProfileSimulation[Profile Simulation API<br/>/api/simulate-vs-profiles<br/>- AI Opponent Testing<br/>- Strategy Analysis<br/>- Exploitation Detection]
        end
    end
    
    subgraph "Data Models"
        UserModel[User Model<br/>- Authentication Data<br/>- Subscription Info<br/>- Profile Information<br/>- OAuth Integration]
        
        SessionModel[UserSession Model<br/>- JWT Token Tracking<br/>- Session Management<br/>- Security Features<br/>- Expiration Handling]
        
        SpotModel[Spot Model<br/>- Game Configuration<br/>- Player Hands<br/>- Board States<br/>- Simulation Results]
        
        ProfileModel[PlayerProfile Model<br/>- Behavioral Parameters<br/>- Playing Style<br/>- Aggression Metrics<br/>- Positional Awareness]
    end
    
    subgraph "External Integrations"
        GoogleOAuth[Google OAuth<br/>- User Authentication<br/>- Profile Data<br/>- Social Login]
        
        StripeAPI[Stripe API<br/>- Payment Processing<br/>- Subscription Management<br/>- Webhook Handling]
        
        DiscourseForum[Discourse Forum<br/>- Community Platform<br/>- SSO Integration<br/>- User Synchronization]
    end
    
    %% Flask app relationships
    FlaskApp --> AuthRoutes
    FlaskApp --> SpotRoutes
    FlaskApp --> SubscriptionRoutes
    FlaskApp --> DocsRoutes
    FlaskApp --> ForumRoutes
    
    FlaskApp --> HealthCheck
    FlaskApp --> EquityAPI
    FlaskApp --> SpotSimulation
    FlaskApp --> ProfileAPI
    FlaskApp --> ProfileSimulation
    
    %% Authentication system
    AuthRoutes --> AuthUtils
    AuthRoutes --> UserModel
    AuthRoutes --> SessionModel
    AuthUtils --> GoogleOAuth
    
    %% Core business logic
    EquityAPI --> EquityEngine
    SpotSimulation --> EquityEngine
    SpotRoutes --> SpotModel
    ProfileAPI --> ProfileModel
    ProfileSimulation --> ProfileSystem
    ProfileSystem --> ProfileModel
    
    %% Business features
    SubscriptionRoutes --> StripeAPI
    SubscriptionRoutes --> UserModel
    ForumRoutes --> DiscourseForum
    
    %% Data model relationships
    UserModel --> SessionModel
    UserModel --> SpotModel
    
    classDef flask fill:#e3f2fd
    classDef route fill:#f3e5f5
    classDef engine fill:#e8f5e8
    classDef model fill:#fff3e0
    classDef external fill:#fce4ec
    classDef endpoint fill:#f1f8e9
    
    class FlaskApp flask
    class AuthRoutes,SpotRoutes,SubscriptionRoutes,DocsRoutes,ForumRoutes route
    class EquityEngine,ProfileSystem engine
    class UserModel,SessionModel,SpotModel,ProfileModel model
    class GoogleOAuth,StripeAPI,DiscourseForum external
    class HealthCheck,EquityAPI,SpotSimulation,ProfileAPI,ProfileSimulation endpoint
```

---

## Deployment Infrastructure

Docker-based deployment architecture with Traefik reverse proxy and service orchestration.

```mermaid
graph TB
    subgraph "Client Layer"
        Users[Users/Browsers<br/>Web Interface]
        Mobile[Mobile Devices<br/>Responsive Web App]
    end
    
    subgraph "Edge Layer"
        Internet[Internet<br/>Public Network]
        CDN[CDN<br/>Static Assets<br/>Global Distribution]
    end
    
    subgraph "Load Balancer & Reverse Proxy"
        Traefik[Traefik v2.10<br/>- SSL Termination<br/>- Load Balancing<br/>- Service Discovery<br/>- Let's Encrypt<br/>- HTTP/HTTPS Routing]
    end
    
    subgraph "Docker Host Environment"
        subgraph "Frontend Services"
            Frontend[Frontend Container<br/>React SPA<br/>- Webpack Dev Server<br/>- Hot Module Reload<br/>- Static File Serving<br/>Port: 3000]
        end
        
        subgraph "Backend Services"
            Backend[Backend Container<br/>Flask API Server<br/>- Python 3.x Runtime<br/>- Multiprocessing<br/>- JWT Authentication<br/>Port: 5001]
        end
        
        subgraph "Database Services"
            PostgreSQL[PostgreSQL 15<br/>Primary Database<br/>- User Data<br/>- Sessions<br/>- Spots<br/>- Subscriptions<br/>Port: 5432]
        end
        
        subgraph "Community Services"
            Discourse[Discourse Forum<br/>Community Platform<br/>- SSO Integration<br/>- User Discussions<br/>- Forum Management<br/>Port: 80]
        end
        
        subgraph "Data Volumes"
            PostgresData[postgres_data<br/>Database Storage<br/>Persistent Volume]
            DiscourseShared[discourse_shared<br/>Forum Assets<br/>Shared Storage]
            DiscourseLogs[discourse_log<br/>Forum Logs<br/>Log Storage]
            TraefikSSL[traefik_letsencrypt<br/>SSL Certificates<br/>ACME Storage]
            Backups[Backups<br/>Database Backups<br/>File System Mount]
        end
    end
    
    subgraph "External Services"
        GoogleOAuth[Google OAuth<br/>Authentication Service<br/>User Profile Data]
        StripeAPI[Stripe API<br/>Payment Processing<br/>Subscription Management<br/>Webhook Endpoints]
        LetsEncrypt[Let's Encrypt<br/>SSL Certificate Authority<br/>Automated Certificates]
    end
    
    subgraph "Monitoring & Logging"
        TraefikDashboard[Traefik Dashboard<br/>Service Monitoring<br/>Port: 8080]
        AppLogs[Application Logs<br/>Flask Logging<br/>Error Tracking]
    end
    
    %% Client connections
    Users --> Internet
    Mobile --> Internet
    Internet --> CDN
    CDN --> Traefik
    Internet --> Traefik
    
    %% Traefik routing
    Traefik --> Frontend
    Traefik --> Backend
    Traefik --> Discourse
    Traefik --> TraefikDashboard
    
    %% Service communications
    Frontend --> Backend
    Backend --> PostgreSQL
    Backend --> GoogleOAuth
    Backend --> StripeAPI
    Backend --> Discourse
    
    %% Volume mounts
    PostgreSQL --> PostgresData
    Discourse --> DiscourseShared
    Discourse --> DiscourseLogs
    Traefik --> TraefikSSL
    PostgreSQL --> Backups
    
    %% External integrations
    Traefik --> LetsEncrypt
    Backend --> GoogleOAuth
    Backend --> StripeAPI
    
    %% Monitoring
    Backend --> AppLogs
    Traefik --> TraefikDashboard
    
    classDef client fill:#e3f2fd
    classDef infrastructure fill:#f3e5f5
    classDef service fill:#e8f5e8
    classDef database fill:#fff3e0
    classDef external fill:#fce4ec
    classDef storage fill:#f1f8e9
    classDef monitoring fill:#fff8e1
    
    class Users,Mobile client
    class Internet,CDN,Traefik infrastructure
    class Frontend,Backend,Discourse service
    class PostgreSQL database
    class GoogleOAuth,StripeAPI,LetsEncrypt external
    class PostgresData,DiscourseShared,DiscourseLogs,TraefikSSL,Backups storage
    class TraefikDashboard,AppLogs monitoring
```

---

## Authentication Flow

Sequence diagram showing the complete authentication, subscription, and session management flow.

```mermaid
sequenceDiagram
    participant User as User/Browser
    participant React as React Frontend
    participant AuthContext as Auth Context
    participant TokenMgr as Token Manager
    participant FlaskAPI as Flask API
    participant Database as PostgreSQL
    participant Google as Google OAuth
    participant Stripe as Stripe API
    
    Note over User,Stripe: User Registration & Authentication Flow
    
    User->>React: Access Application
    React->>AuthContext: Check Authentication Status
    AuthContext->>TokenMgr: Get Access Token
    TokenMgr-->>AuthContext: No Token Found
    AuthContext-->>React: User Not Authenticated
    React-->>User: Show Login/Register Modal
    
    User->>React: Click "Sign Up with Google"
    React->>Google: Request OAuth Token
    Google-->>React: Return ID Token
    React->>AuthContext: GoogleLogin(tokenId)
    AuthContext->>FlaskAPI: POST /auth/google
    FlaskAPI->>Google: Verify ID Token
    Google-->>FlaskAPI: Token Valid + User Info
    FlaskAPI->>Database: Check if User Exists
    Database-->>FlaskAPI: User Not Found
    FlaskAPI->>Database: Create New User
    Database-->>FlaskAPI: User Created
    FlaskAPI->>FlaskAPI: Generate JWT Tokens
    FlaskAPI->>Database: Store User Session
    Database-->>FlaskAPI: Session Stored
    FlaskAPI-->>AuthContext: Return Tokens + User Data
    AuthContext->>TokenMgr: Store Tokens
    AuthContext-->>React: Authentication Success
    React-->>User: Redirect to Application
    
    Note over User,Stripe: Subscription Flow
    
    User->>React: Navigate to Pricing
    React->>FlaskAPI: GET /api/subscription/plans
    FlaskAPI-->>React: Return Available Plans
    React-->>User: Display Pricing Plans
    
    User->>React: Select Pro Plan
    React->>FlaskAPI: POST /api/subscription/create-checkout-session
    FlaskAPI->>Stripe: Create Checkout Session
    Stripe-->>FlaskAPI: Return Session URL
    FlaskAPI-->>React: Return Checkout URL
    React-->>User: Redirect to Stripe Checkout
    
    User->>Stripe: Complete Payment
    Stripe->>FlaskAPI: Webhook: Payment Success
    FlaskAPI->>Database: Update User Subscription
    Database-->>FlaskAPI: Subscription Updated
    FlaskAPI-->>Stripe: Webhook Acknowledged
    Stripe-->>User: Redirect to Success Page
    
    Note over User,Stripe: Spot Simulation Flow
    
    User->>React: Navigate to Spot Mode
    React->>AuthContext: Get Current User
    AuthContext-->>React: Return User + Token
    React->>FlaskAPI: GET /spots (with JWT)
    FlaskAPI->>FlaskAPI: Validate JWT Token
    FlaskAPI->>Database: Get User Spots
    Database-->>FlaskAPI: Return Spots
    FlaskAPI-->>React: Return User Spots
    React-->>User: Display Saved Spots
    
    User->>React: Configure New Spot
    React->>FlaskAPI: POST /spot-simulation
    FlaskAPI->>FlaskAPI: Run Equity Simulation
    FlaskAPI->>FlaskAPI: Multiprocessing Calculation
    FlaskAPI-->>React: Return Simulation Results
    React-->>User: Display Equity Analysis
    
    User->>React: Save Spot
    React->>FlaskAPI: POST /spots (with JWT)
    FlaskAPI->>Database: Save Spot Configuration
    Database-->>FlaskAPI: Spot Saved
    FlaskAPI-->>React: Confirmation
    React-->>User: Show Success Message
    
    Note over User,Stripe: Session Management
    
    AuthContext->>FlaskAPI: GET /auth/me (periodic refresh)
    FlaskAPI->>Database: Validate Session
    Database-->>FlaskAPI: Session Valid
    FlaskAPI-->>AuthContext: Return User Data
    
    User->>React: Logout
    React->>AuthContext: Logout()
    AuthContext->>FlaskAPI: POST /auth/logout
    FlaskAPI->>Database: Deactivate Session
    Database-->>FlaskAPI: Session Deactivated
    FlaskAPI-->>AuthContext: Logout Success
    AuthContext->>TokenMgr: Clear Tokens
    AuthContext-->>React: Logout Complete
    React-->>User: Redirect to Landing Page
```

---

## Diagram Usage

### For Developers
- **System Architecture**: Understanding overall application structure
- **Database Schema**: Database design and relationship planning
- **Component Hierarchy**: Frontend development and component organization
- **Backend API Structure**: API development and service integration
- **Authentication Flow**: Security implementation and user management

### For DevOps/Infrastructure
- **Deployment Infrastructure**: Container orchestration and service management
- **System Architecture**: Service dependencies and networking
- **Authentication Flow**: Security and session management requirements

### For Product/Business
- **System Architecture**: Feature capabilities and technical limitations
- **Authentication Flow**: User experience and subscription management
- **Deployment Infrastructure**: Scalability and operational requirements

### Diagram Maintenance

These diagrams should be updated when:
- New components or services are added
- Database schema changes
- API endpoints are modified
- Deployment architecture evolves
- Authentication/authorization changes

All diagrams use Mermaid syntax and can be rendered in:
- GitHub README files
- Documentation platforms (GitBook, Notion, etc.)
- Mermaid Live Editor
- VS Code with Mermaid extensions
- CI/CD documentation generation tools 