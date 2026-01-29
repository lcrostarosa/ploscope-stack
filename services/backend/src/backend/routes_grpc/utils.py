"""Utility functions for gRPC routes_grpc."""

import datetime

from ..protos import common_pb2


def _to_proto_timestamp(dt: datetime.datetime) -> "common_pb2.google_dot_protobuf_dot_timestamp__pb2.Timestamp":
    """Convert datetime to protobuf timestamp."""
    from google.protobuf.timestamp_pb2 import Timestamp as _Ts

    ts = _Ts()
    ts.FromDatetime(dt)
    return ts


def _user_dict_to_proto(user_dict: dict) -> common_pb2.User:
    """Convert user dictionary to protobuf User message."""
    return common_pb2.User(
        id=int(user_dict.get("id", 0)),
        email=user_dict.get("email", ""),
        username=user_dict.get("username", ""),
        is_active=bool(user_dict.get("is_active", False)),
        is_verified=bool(user_dict.get("is_verified", False)),
        created_at=_to_proto_timestamp(user_dict.get("created_at", datetime.datetime.utcnow())),
        updated_at=_to_proto_timestamp(user_dict.get("updated_at", datetime.datetime.utcnow())),
        subscription_status=user_dict.get("subscription_status", ""),
        credits_remaining=int(user_dict.get("credits_remaining", 0)),
    )
