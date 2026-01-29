# PLOSolver Architecture Overview

This document provides a comprehensive overview of the PLOSolver application architecture, including system components, data flow, and infrastructure design.

## System Architecture

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

## Architecture Components

### Client Layer
- **Browser Interface**: Primary web-based user interface
- **Mobile App**: Future extension for mobile platforms

### Frontend Services
- **React SPA**: Single-page application with component-based architecture
- **Webpack Dev Server**: Development server with hot reload capabilities

### Backend Services
- **Flask API Server**: RESTful API server handling business logic
- **Core Modules**:
  - **Authentication**: JWT tokens, OAuth, session management
  - **Equity Calculator**: PLO simulations with multiprocessing
  - **Spot Management**: Save/load poker scenarios
  - **Player Profiles**: AI opponent modeling
  - **Subscription Service**: Payment and tier management

### External Integrations
- **Google OAuth**: User authentication and profile data
- **Stripe**: Payment processing and subscription management
- **Discourse Forum**: Community platform with SSO

### Data Layer
- **PostgreSQL**: Primary database for structured data
- **File System**: Custom profiles, logs, and static assets

### Infrastructure
- **Docker**: Containerized services for scalability
- **Traefik**: Reverse proxy with SSL termination and load balancing

## Key Features

1. **Multi-Mode Poker Analysis**
   - Live Mode: Interactive poker gameplay
   - Spot Mode: Scenario analysis and saving
   - Training Mode: AI opponent training

2. **Advanced Equity Calculations**
   - Monte Carlo simulations
   - Multiprocessing for performance
   - Hand strength analysis

3. **User Management**
   - OAuth authentication
   - Subscription tiers
   - Profile management

4. **Community Features**
   - Integrated forum
   - User discussions
   - Knowledge sharing

5. **Scalable Infrastructure**
   - Docker containerization
   - Load balancing
   - SSL/TLS encryption 