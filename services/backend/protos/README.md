# PLOSolver Protocol Buffers

This directory contains the Protocol Buffer definitions for the PLOSolver gRPC services, organized into logical domain-specific files.

## File Structure

### Domain-Specific Files

- **`common.proto`** - Shared messages used across multiple services
  - `User` - User information
  - `Error` - Error handling
  - `PaginationRequest` / `PaginationResponse` - Pagination utilities

- **`auth.proto`** - Authentication and user management
  - `AuthService` - User registration, login, profile management
  - Authentication-related messages (RegisterRequest, LoginRequest, etc.)

- **`solver.proto`** - Game analysis and solver functionality
  - `SolverService` - Spot analysis, solver configuration
  - Game state and analysis messages (GameState, AnalysisResult, etc.)

- **`job.proto`** - Job management and processing
  - `JobService` - Job creation, monitoring, and management
  - Job-related messages (Job, CreateJobRequest, etc.)

- **`subscription.proto`** - Subscription and billing
  - `SubscriptionService` - Subscription management, billing history
  - Billing-related messages (Subscription, Usage, BillingRecord, etc.)

- **`hand_history.proto`** - Hand history file management
  - `HandHistoryService` - File upload, analysis, and management
  - File-related messages (HandHistory, AnalysisSettings, etc.)

- **`core.proto`** - System health and core functionality
  - `CoreService` - Health checks, system status, user statistics
  - System-related messages (HealthCheckResponse, UserStats, etc.)





## Usage

### For New Development

Import the specific domain files you need:

```protobuf
import "common.proto";
import "auth.proto";
import "solver.proto";
```



## Benefits of This Structure

1. **Modularity** - Each service domain is self-contained
2. **Maintainability** - Easier to find and modify specific functionality
3. **Reusability** - Common messages can be imported independently
4. **Scalability** - New services can be added without affecting existing ones
5. **Team Development** - Different teams can work on different domains

## Migration Guide

### From Monolithic to Modular

1. **Update imports** in your proto files:
   ```protobuf
   // Old
   import "plosolver.proto";

   // New
   import "common.proto";
   import "auth.proto";
   ```

2. **Update package references** in your code:
   ```protobuf
   // Old
   plosolver.User

   // New
   plosolver.common.User
   ```

3. **Update service references**:
   ```protobuf
   // Old
   plosolver.AuthService

   // New
   plosolver.auth.AuthService
   ```

### Code Generation

Generate code for specific domains:

```bash
# Generate for all routes_grpc
protoc --go_out=. --go-grpc_out=. *.proto

# Generate for specific domains
protoc --go_out=. --go-grpc_out=. common.proto auth.proto solver.proto
```

## Package Naming Convention

Each domain uses the `plosolver.{domain}` package structure:
- `plosolver.common`
- `plosolver.auth`
- `plosolver.solver`
- `plosolver.job`
- `plosolver.subscription`
- `plosolver.hand_history`
- `plosolver.core`
