# PLOSolver Protos - Python

Python package containing Protocol Buffer definitions for PLOSolver gRPC services.

## Installation

```bash
# From Nexus (recommended)
pip install plosolver-protos --extra-index-url https://nexus.ploscope.com/repository/pypi-internal/simple/

# Or from PyPI (if published publicly)
pip install plosolver-protos
```

## Usage

### Basic Usage

```python
import grpc
from plosolver_protos import AuthServiceStub, User, RegisterRequest

# Create a gRPC channel
channel = grpc.insecure_channel('your-server:50051')

# Create a client
auth_client = AuthServiceStub(channel)

# Create a request
request = RegisterRequest()
request.email = "user@example.com"
request.password = "password123"

# Make the call
response = auth_client.Register(request)
print(f"User ID: {response.user.id}")
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

## Development

This package is automatically generated from the protobuf definitions in the main PLOScope repository. The source `.proto` files are located in the `protos/` directory of the main project.

To regenerate the Python bindings:

```bash
# From the main project root
python scripts/build_protos.py --python-only
```

## License

All Rights Reserved - PLOSolver Team


