import * as grpc from '@grpc/grpc-js';
import * as protoLoader from '@grpc/proto-loader';
import * as path from 'path';

// Load the proto files from the project root
const PROTO_PATH = path.join(__dirname, '../../../protos');
const packageDefinition = protoLoader.loadSync([
  path.join(PROTO_PATH, 'common.proto'),
  path.join(PROTO_PATH, 'auth.proto'),
  path.join(PROTO_PATH, 'solver.proto'),
  path.join(PROTO_PATH, 'job.proto'),
  path.join(PROTO_PATH, 'subscription.proto'),
  path.join(PROTO_PATH, 'hand_history.proto'),
  path.join(PROTO_PATH, 'core.proto'),
], {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true
});

// Load the package definition
const plosolver = grpc.loadPackageDefinition(packageDefinition) as any;

// Export the main package
export { plosolver };

// Export specific services for easier access
export const AuthService = plosolver.plosolver?.auth?.AuthService;
export const SolverService = plosolver.plosolver?.solver?.SolverService;
export const JobService = plosolver.plosolver?.job?.JobService;
export const SubscriptionService = plosolver.plosolver?.subscription?.SubscriptionService;
export const HandHistoryService = plosolver.plosolver?.hand_history?.HandHistoryService;
export const CoreService = plosolver.plosolver?.core?.CoreService;

// Export message types from common
export const User = plosolver.plosolver?.common?.User;
export const Error = plosolver.plosolver?.common?.Error;
export const PaginationRequest = plosolver.plosolver?.common?.PaginationRequest;
export const PaginationResponse = plosolver.plosolver?.common?.PaginationResponse;

// Export auth message types
export const RegisterRequest = plosolver.plosolver?.auth?.RegisterRequest;
export const LoginRequest = plosolver.plosolver?.auth?.LoginRequest;
export const AuthResponse = plosolver.plosolver?.auth?.AuthResponse;

// Export solver message types
export const AnalyzeSpotRequest = plosolver.plosolver?.solver?.AnalyzeSpotRequest;
export const AnalyzeSpotResponse = plosolver.plosolver?.solver?.AnalyzeSpotResponse;
export const SolverConfig = plosolver.plosolver?.solver?.SolverConfig;

// Export job message types
export const Job = plosolver.plosolver?.job?.Job;
export const CreateJobRequest = plosolver.plosolver?.job?.CreateJobRequest;
export const JobResponse = plosolver.plosolver?.job?.JobResponse;

// Re-export grpc for convenience
export { grpc };


