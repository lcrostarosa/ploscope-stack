# PLOSolver Protos - Node.js

Node.js package containing Protocol Buffer definitions for PLOSolver gRPC services.

## Installation

```bash
npm install @plosolver/protos
```

## Usage

### Basic Usage

```typescript
import { AuthService, RegisterRequest, grpc } from '@plosolver/protos';

// Create a gRPC channel
const channel = new grpc.Channel('your-server:50051', grpc.credentials.createInsecure());

// Create a client
const authClient = new AuthService(channel);

// Create a request
const request = new RegisterRequest();
request.setEmail('user@example.com');
request.setPassword('password123');

// Make the call
authClient.register(request, (error, response) => {
  if (error) {
    console.error('Error:', error);
  } else {
    console.log('User ID:', response.getUser().getId());
  }
});
```

### TypeScript Support

This package includes full TypeScript definitions:

```typescript
import {
  AuthService,
  SolverService,
  User,
  AnalyzeSpotRequest,
  grpc
} from '@plosolver/protos';

// All types are properly typed
const user: User = new User();
user.setEmail('user@example.com');

const request: AnalyzeSpotRequest = new AnalyzeSpotRequest();
// ... set request properties
```

### Available Services

- **AuthService**: User authentication and management
- **SolverService**: Game analysis and solver functionality
- **JobService**: Job management and processing
- **SubscriptionService**: Subscription and billing
- **HandHistoryService**: Hand history file management
- **CoreService**: System health and core functionality

### Available Message Types

#### Common Messages
- `User`: User information
- `Error`: Error handling
- `PaginationRequest`/`PaginationResponse`: Pagination utilities

#### Auth Messages
- `RegisterRequest`/`RegisterResponse`: User registration
- `LoginRequest`/`LoginResponse`: User login
- `GetProfileRequest`/`GetProfileResponse`: User profile management

#### Solver Messages
- `AnalyzeSpotRequest`/`AnalyzeSpotResponse`: Game spot analysis
- `SolverConfig`: Solver configuration
- `GameState`: Game state representation

#### Job Messages
- `Job`: Job information
- `CreateJobRequest`/`JobResponse`: Job creation and management
- `JobStatus`: Job status enumeration

### Async/Await Support

```typescript
import { promisify } from 'util';
import { AuthService, RegisterRequest, grpc } from '@plosolver/protos';

const channel = new grpc.Channel('your-server:50051', grpc.credentials.createInsecure());
const authClient = new AuthService(channel);

// Promisify the client methods
const registerAsync = promisify(authClient.register.bind(authClient));

async function registerUser() {
  try {
    const request = new RegisterRequest();
    request.setEmail('user@example.com');
    request.setPassword('password123');

    const response = await registerAsync(request);
    console.log('User registered:', response.getUser().getId());
  } catch (error) {
    console.error('Registration failed:', error);
  }
}
```

## Development

This package is automatically generated from the protobuf definitions in the main PLOScope repository. The source `.proto` files are located in the `protos/` directory of the main project.

To regenerate the Node.js bindings:

```bash
# From the main project root
python scripts/build_protos.py --nodejs-only
```

## License

All Rights Reserved - PLOSolver Team


