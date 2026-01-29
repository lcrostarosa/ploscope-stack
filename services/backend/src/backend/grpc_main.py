import os

from src.backend.main import create_grpc_server, run_grpc_server


def main() -> None:
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("GRPC_PORT", "50051"))

    server = create_grpc_server()
    run_grpc_server(server, host, port)


if __name__ == "__main__":
    main()
