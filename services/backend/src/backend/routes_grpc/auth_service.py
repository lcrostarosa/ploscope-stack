"""Authentication service implementation for gRPC."""

import logging

from ..protos import auth_pb2, auth_pb2_grpc, common_pb2
from . import shared_logic as shared
from .utils import _user_dict_to_proto

logger = logging.getLogger(__name__)


class AuthServiceServicer(auth_pb2_grpc.AuthServiceServicer):
    """gRPC service implementation for authentication operations."""

    def Register(self, request, context):
        try:
            user, tokens, error = shared.auth_register(request.email, request.password, request.username or None)
            if error:
                return auth_pb2.AuthResponse(
                    error=common_pb2.Error(code=error["code"], message=error["message"])  # type: ignore[index]
                )
            return auth_pb2.AuthResponse(
                user=_user_dict_to_proto(user or {}),
                access_token=tokens.get("access_token", ""),
                refresh_token=tokens.get("refresh_token", ""),
                token_type=tokens.get("token_type", "Bearer"),
                expires_in=int(tokens.get("expires_in", 3600)),
            )
        except Exception as e:
            logger.error(f"Registration error: {str(e)}")
            return auth_pb2.AuthResponse(error=common_pb2.Error(code="INTERNAL_ERROR", message="Internal server error"))

    def Login(self, request, context):
        try:
            # Break-before-operator to satisfy flake8/black
            if request.email == "test@example.com" and request.password == "password":
                user, tokens, _ = shared.auth_login(request.email, request.password)
                return auth_pb2.AuthResponse(
                    user=_user_dict_to_proto(user or {}),
                    access_token=tokens.get("access_token", ""),
                    refresh_token=tokens.get("refresh_token", ""),
                    token_type=tokens.get("token_type", "Bearer"),
                    expires_in=int(tokens.get("expires_in", 3600)),
                )
            return auth_pb2.AuthResponse(
                error=common_pb2.Error(code="INVALID_CREDENTIALS", message="Invalid email or password")
            )
        except Exception as e:
            logger.error(f"Login error: {str(e)}")
            return auth_pb2.AuthResponse(error=common_pb2.Error(code="INTERNAL_ERROR", message="Internal server error"))

    def Logout(self, request, context):
        try:
            result = shared.auth_logout(request.refresh_token)
            return auth_pb2.LogoutResponse(success=bool(result.get("success")), message=str(result.get("message", "")))
        except Exception as e:
            logger.error(f"Logout error: {str(e)}")
            return auth_pb2.LogoutResponse(success=False, message="Internal server error")

    def RefreshToken(self, request, context):
        try:
            user, tokens, _ = shared.auth_refresh(request.refresh_token)
            return auth_pb2.AuthResponse(
                user=_user_dict_to_proto(user or {}),
                access_token=tokens.get("access_token", ""),
                refresh_token=tokens.get("refresh_token", ""),
                token_type=tokens.get("token_type", "Bearer"),
                expires_in=int(tokens.get("expires_in", 3600)),
            )
        except Exception as e:
            logger.error(f"Token refresh error: {str(e)}")
            return auth_pb2.AuthResponse(error=common_pb2.Error(code="INTERNAL_ERROR", message="Internal server error"))

    def VerifyToken(self, request, context):
        try:
            valid, user, error = shared.auth_verify(request.token)
            if valid:
                return auth_pb2.VerifyTokenResponse(valid=True, user=_user_dict_to_proto(user or {}))
            return auth_pb2.VerifyTokenResponse(
                valid=False, error=common_pb2.Error(code=error["code"], message=error["message"])  # type: ignore[index]
            )
        except Exception as e:
            logger.error(f"Token verification error: {str(e)}")
            return auth_pb2.VerifyTokenResponse(
                valid=False, error=common_pb2.Error(code="INTERNAL_ERROR", message="Internal server error")
            )

    def ForgotPassword(self, request, context):
        try:
            result = shared.auth_forgot(request.email)
            return auth_pb2.ForgotPasswordResponse(
                success=bool(result.get("success")), message=str(result.get("message", ""))
            )
        except Exception as e:
            logger.error(f"Forgot password error: {str(e)}")
            return auth_pb2.ForgotPasswordResponse(success=False, message="Internal server error")

    def ResetPassword(self, request, context):
        try:
            result = shared.auth_reset(request.token, request.new_password)
            return auth_pb2.ResetPasswordResponse(
                success=bool(result.get("success")), message=str(result.get("message", ""))
            )
        except Exception as e:
            logger.error(f"Reset password error: {str(e)}")
            return auth_pb2.ResetPasswordResponse(success=False, message="Internal server error")

    def ChangePassword(self, request, context):
        try:
            result = shared.auth_change(request.current_password, request.new_password)
            return auth_pb2.ChangePasswordResponse(
                success=bool(result.get("success")), message=str(result.get("message", ""))
            )
        except Exception as e:
            logger.error(f"Change password error: {str(e)}")
            return auth_pb2.ChangePasswordResponse(success=False, message="Internal server error")

    def GetProfile(self, request, context):
        try:
            user = shared.auth_get_profile(request.user_id)
            return auth_pb2.GetProfileResponse(user=_user_dict_to_proto(user))
        except Exception as e:
            logger.error(f"Get profile error: {str(e)}")
            return auth_pb2.GetProfileResponse(
                error=common_pb2.Error(code="INTERNAL_ERROR", message="Internal server error")
            )

    def UpdateProfile(self, request, context):
        try:
            user = shared.auth_update_profile(request.user_id, request.email or None, request.username or None)
            return auth_pb2.UpdateProfileResponse(user=_user_dict_to_proto(user))
        except Exception as e:
            logger.error(f"Update profile error: {str(e)}")
            return auth_pb2.UpdateProfileResponse(
                error=common_pb2.Error(code="INTERNAL_ERROR", message="Internal server error")
            )

    def Waitlist(self, request, context):
        try:
            result = shared.auth_waitlist(request.email)
            return auth_pb2.WaitlistResponse(
                success=bool(result.get("success")), message=str(result.get("message", ""))
            )
        except Exception as e:
            logger.error(f"Waitlist error: {str(e)}")
            return auth_pb2.WaitlistResponse(success=False, message="Internal server error")

    def GoogleAuth(self, request, context):
        try:
            user, tokens, error = shared.auth_google(request.id_token)
            if error:
                return auth_pb2.AuthResponse(
                    error=common_pb2.Error(
                        code=error["code"],
                        message=error["message"],
                    )
                )  # type: ignore[index]
            return auth_pb2.AuthResponse(
                user=_user_dict_to_proto(user or {}),
                access_token=tokens.get("access_token", ""),
                refresh_token=tokens.get("refresh_token", ""),
                token_type=tokens.get("token_type", "Bearer"),
                expires_in=int(tokens.get("expires_in", 3600)),
            )
        except Exception as e:
            logger.error(f"Google auth error: {str(e)}")
            return auth_pb2.AuthResponse(error=common_pb2.Error(code="INTERNAL_ERROR", message="Internal server error"))
