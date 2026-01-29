"""Solver service implementation for gRPC."""

import logging

from ..protos import common_pb2, solver_pb2, solver_pb2_grpc
from . import shared_logic as shared

logger = logging.getLogger(__name__)


class SolverServiceServicer(solver_pb2_grpc.SolverServiceServicer):
    """gRPC service implementation for solver operations."""

    def GetSolverConfig(self, request, context):
        """Get solver configuration settings."""
        try:
            cfg = shared.get_solver_config()
            config = solver_pb2.SolverConfig(
                max_players=int(cfg.get("max_players", 6)),
                supported_game_types=list(cfg.get("supported_game_types", [])),
                default_stack_size=int(cfg.get("default_stack_size", 100)),
                min_stack_size=int(cfg.get("min_stack_size", 10)),
                max_stack_size=int(cfg.get("max_stack_size", 1000)),
                supported_positions=list(cfg.get("supported_positions", [])),
                supported_board_textures=list(cfg.get("supported_board_textures", [])),
                solver_engines=list(cfg.get("solver_engines", [])),
                accuracy_levels=list(cfg.get("accuracy_levels", [])),
            )
            return solver_pb2.SolverConfigResponse(config=config)
        except Exception as e:
            logger.error(f"Error getting solver config: {str(e)}")
            return solver_pb2.SolverConfigResponse(
                error=common_pb2.Error(code="INTERNAL_ERROR", message="Internal server error")
            )

    def GetHandBuckets(self, request, context):
        """Get pre-computed hand buckets for analysis."""
        try:
            buckets = shared.get_hand_buckets()
            hand_buckets = {
                k: solver_pb2.HandBucket(
                    description=v.get("description", ""),
                    examples=list(v.get("examples", [])),
                    equity_range=v.get("equity_range", ""),
                    play_frequency=v.get("play_frequency", ""),
                )
                for k, v in buckets.items()
            }
            return solver_pb2.HandBucketsResponse(hand_buckets=hand_buckets)
        except Exception as e:
            logger.error(f"Error getting hand buckets: {str(e)}")
            return solver_pb2.HandBucketsResponse(
                error=common_pb2.Error(code="INTERNAL_ERROR", message="Internal server error")
            )

    def AnalyzeSpot(self, request, context):
        """Start a spot analysis job."""
        try:
            data = shared.analyze_spot(request.user_id)
            return solver_pb2.AnalyzeSpotResponse(
                job_id=data.get("job_id", ""), status=data.get("status", ""), message=data.get("message", "")
            )
        except Exception as e:
            logger.error(f"Error creating analysis job: {str(e)}")
            return solver_pb2.AnalyzeSpotResponse(
                error=common_pb2.Error(code="INTERNAL_ERROR", message="Internal server error")
            )
