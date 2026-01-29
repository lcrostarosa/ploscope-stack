"""
Simple HTTP server for serving Celery worker metrics.

This module provides a lightweight HTTP server to expose Prometheus metrics
and health check endpoints for the Celery worker.
"""

import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse

from core.utils.logging_utils import get_enhanced_logger

from src.celery_worker.metrics import get_health_response, get_metrics_response, get_ready_response

logger = get_enhanced_logger(__name__)


class MetricsHTTPRequestHandler(BaseHTTPRequestHandler):
    """HTTP request handler for metrics endpoints."""

    def do_GET(self):
        """Handle GET requests."""
        parsed_path = urlparse(self.path)
        path = parsed_path.path

        try:
            if path == "/metrics":
                self._handle_metrics()
            elif path == "/health":
                self._handle_health()
            elif path == "/ready":
                self._handle_ready()
            else:
                self._handle_not_found()
        except Exception as e:
            logger.error("Error handling request %s: %s", path, e)
            self._handle_error()

    def _handle_metrics(self):
        """Handle /metrics endpoint."""
        try:
            metrics_data = get_metrics_response()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
            self.end_headers()
            self.wfile.write(metrics_data.encode("utf-8"))
        except Exception as e:
            logger.error("Error generating metrics: %s", e)
            self.send_response(500)
            self.end_headers()

    def _handle_health(self):
        """Handle /health endpoint."""
        try:
            health_data = get_health_response()
            import json

            status_code = 200 if health_data.get("status") == "healthy" else 503

            self.send_response(status_code)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(health_data).encode("utf-8"))
        except Exception as e:
            logger.error("Error generating health response: %s", e)
            self.send_response(500)
            self.end_headers()

    def _handle_ready(self):
        """Handle /ready endpoint."""
        try:
            ready_data = get_ready_response()
            import json

            status_code = 200 if ready_data.get("status") == "ready" else 503

            self.send_response(status_code)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(ready_data).encode("utf-8"))
        except Exception as e:
            logger.error("Error generating ready response: %s", e)
            self.send_response(500)
            self.end_headers()

    def _handle_not_found(self):
        """Handle 404 responses."""
        self.send_response(404)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"Not Found")

    def _handle_error(self):
        """Handle 500 responses."""
        self.send_response(500)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"Internal Server Error")

    def log_message(self, format, *args):
        """Override to use our logger instead of stderr."""
        logger.info(format % args)


class MetricsServer:
    """Simple HTTP server for serving metrics."""

    def __init__(self, host: str = "0.0.0.0", port: int = 8000):
        self.host = host
        self.port = port
        self.server = None
        self.thread = None
        self._running = False

    def start(self):
        """Start the metrics server."""
        if self._running:
            logger.warning("Metrics server already running")
            return

        try:
            self.server = HTTPServer((self.host, self.port), MetricsHTTPRequestHandler)
            self.thread = threading.Thread(target=self._run_server, daemon=True)
            self.thread.start()
            self._running = True
            logger.info("Metrics server started on %s:%d", self.host, self.port)
        except Exception as e:
            logger.error("Failed to start metrics server: %s", e)
            raise

    def stop(self):
        """Stop the metrics server."""
        if not self._running:
            return

        try:
            self._running = False
            if self.server:
                self.server.shutdown()
                self.server.server_close()
            if self.thread:
                self.thread.join(timeout=5)
            logger.info("Metrics server stopped")
        except Exception as e:
            logger.error("Failed to stop metrics server: %s", e)

    def _run_server(self):
        """Run the HTTP server."""
        try:
            self.server.serve_forever()
        except Exception as e:
            if self._running:  # Only log if we're supposed to be running
                logger.error("Metrics server error: %s", e)


def start_metrics_server(host: str = "0.0.0.0", port: int = 8000) -> MetricsServer:
    """Start the metrics server and return the server instance."""
    server = MetricsServer(host, port)
    server.start()
    return server
