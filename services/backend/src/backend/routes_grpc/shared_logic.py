import datetime
from typing import Any, Dict, Optional, Tuple

# Types
UserDict = Dict[str, Any]
ErrorDict = Optional[Dict[str, str]]


def utc_now() -> datetime.datetime:
    return datetime.datetime.utcnow()


# -------- Core / Health --------


def get_root_health() -> Dict[str, Any]:
    return {
        "status": "healthy",
        "service": "PLOSolver Backend",
        "timestamp": utc_now().isoformat(),
    }


def get_api_health() -> Dict[str, Any]:
    return {"status": "healthy", "api": "REST", "version": "1.0.0"}


# -------- Solver --------


def get_solver_config() -> Dict[str, Any]:
    return {
        "max_players": 6,
        "supported_game_types": ["plo", "plo_bomb_pot"],
        "default_stack_size": 100,
        "min_stack_size": 10,
        "max_stack_size": 1000,
        "supported_positions": ["UTG", "HJ", "CO", "BTN", "SB", "BB"],
        "supported_board_textures": ["paired", "monotone", "rainbow", "two_tone"],
        "solver_engines": ["cfr", "fictitious_play"],
        "accuracy_levels": ["fast", "medium", "high", "tournament"],
    }


def get_hand_buckets() -> Dict[str, Any]:
    return {
        "premium": {
            "description": "Premium PLO hands",
            "examples": ["AAKK", "AAJJ", "AAQQ", "KKQQ"],
            "equity_range": "65-85%",
            "play_frequency": "100%",
        },
        "strong": {
            "description": "Strong PLO hands",
            "examples": ["AAKJ", "AAJT", "KKJT", "QQJT"],
            "equity_range": "55-65%",
            "play_frequency": "85-95%",
        },
        "medium": {
            "description": "Medium strength PLO hands",
            "examples": ["AJTX", "KQJ9", "JT98", "T987"],
            "equity_range": "45-55%",
            "play_frequency": "60-80%",
        },
    }


def analyze_spot(user_id: str) -> Dict[str, Any]:
    job_id = f"job_{utc_now().strftime('%Y%m%d_%H%M%S')}"
    return {"job_id": job_id, "status": "queued", "message": "Analysis job created successfully"}


# -------- Jobs --------


def create_job(user_id: str, job_type: str, parameters: Dict[str, Any], priority: int) -> Dict[str, Any]:
    job_id = f"job_{utc_now().strftime('%Y%m%d_%H%M%S')}"
    return {
        "id": job_id,
        "user_id": user_id,
        "job_type": job_type,
        "status": "queued",
        "parameters": parameters,
        "priority": priority,
        "progress": 0.0,
    }


def get_job_status(job_id: str, user_id: str) -> Dict[str, Any]:
    return {
        "id": job_id,
        "user_id": user_id,
        "job_type": "spot_analysis",
        "status": "completed",
        "parameters": {"game_type": "plo"},
        "result": {"equity": 0.65},
        "priority": 1,
        "progress": 100.0,
        "error_message": "",
    }


# -------- Core System Status --------


def get_system_status() -> Dict[str, Any]:
    return {
        "status": "healthy",
        "routes_grpc": {"database": "healthy", "redis": "healthy", "celery": "healthy"},
        "metrics": {"cpu_usage": 25.5, "memory_usage": 45.2, "active_connections": 12},
    }


# -------- Auth --------


def _build_user(id_value: int, email: str, username: str, subscription_status: str, credits_remaining: int) -> UserDict:
    now = utc_now()
    return {
        "id": id_value,
        "email": email,
        "username": username,
        "is_active": True,
        "is_verified": subscription_status != "FREE",
        "created_at": now,
        "updated_at": now,
        "subscription_status": subscription_status,
        "credits_remaining": credits_remaining,
    }


def auth_register(
    email: str, password: str, username: Optional[str]
) -> Tuple[Optional[UserDict], Dict[str, Any], ErrorDict]:
    if not email or "@" not in email:
        return None, {}, {"code": "INVALID_EMAIL", "message": "Invalid email format"}
    if not password or len(password) < 6:
        return None, {}, {"code": "INVALID_PASSWORD", "message": "Password must be at least 6 characters"}
    if email == "existing@example.com":
        return None, {}, {"code": "USER_EXISTS", "message": "User with this email already exists"}

    user = _build_user(1, email, username or "", "FREE", 10)
    tokens = {
        "access_token": "mock_access_token",
        "refresh_token": "mock_refresh_token",
        "token_type": "Bearer",
        "expires_in": 3600,
    }
    return user, tokens, None


def auth_login(email: str, password: str) -> Tuple[Optional[UserDict], Dict[str, Any], ErrorDict]:
    if email == "test@example.com" and password == "password":
        user = _build_user(1, email, "testuser", "premium", 100)
        tokens = {
            "access_token": "mock_access_token",
            "refresh_token": "mock_refresh_token",
            "token_type": "Bearer",
            "expires_in": 3600,
        }
        return user, tokens, None
    return None, {}, {"code": "INVALID_CREDENTIALS", "message": "Invalid email or password"}


def auth_logout(refresh_token: str) -> Dict[str, Any]:
    return {"success": True, "message": "Logged out successfully"}


def auth_refresh(refresh_token: str) -> Tuple[Optional[UserDict], Dict[str, Any], ErrorDict]:
    user = _build_user(1, "test@example.com", "testuser", "premium", 100)
    tokens = {
        "access_token": "new_mock_access_token",
        "refresh_token": "new_mock_refresh_token",
        "token_type": "Bearer",
        "expires_in": 3600,
    }
    return user, tokens, None


def auth_verify(token: str) -> Tuple[bool, Optional[UserDict], ErrorDict]:
    if token == "valid_token":
        user = _build_user(1, "test@example.com", "testuser", "premium", 100)
        return True, user, None
    return False, None, {"code": "INVALID_TOKEN", "message": "Invalid or expired token"}


def auth_forgot(email: str) -> Dict[str, Any]:
    if not email or "@" not in email:
        return {"success": False, "message": "Invalid email format"}
    return {"success": True, "message": "Password reset email sent successfully"}


def auth_reset(token: str, new_password: str) -> Dict[str, Any]:
    if not token or not new_password:
        return {"success": False, "message": "Token and new password are required"}
    if len(new_password) < 6:
        return {"success": False, "message": "Password must be at least 6 characters"}
    return {"success": True, "message": "Password reset successfully"}


def auth_change(current_password: str, new_password: str) -> Dict[str, Any]:
    if not current_password or not new_password:
        return {"success": False, "message": "Current and new passwords are required"}
    if len(new_password) < 6:
        return {"success": False, "message": "New password must be at least 6 characters"}
    return {"success": True, "message": "Password changed successfully"}


def auth_get_profile(user_id: str) -> UserDict:
    return _build_user(int(user_id) if user_id.isdigit() else 1, "test@example.com", "testuser", "premium", 100)


def auth_update_profile(user_id: str, email: Optional[str], username: Optional[str]) -> UserDict:
    return _build_user(
        int(user_id) if user_id.isdigit() else 1, email or "test@example.com", username or "testuser", "premium", 100
    )


def auth_waitlist(email: str) -> Dict[str, Any]:
    if not email or "@" not in email:
        return {"success": False, "message": "Invalid email format"}
    return {"success": True, "message": "Added to waitlist successfully"}


def auth_google(id_token: str) -> Tuple[Optional[UserDict], Dict[str, Any], ErrorDict]:
    if not id_token:
        return None, {}, {"code": "INVALID_TOKEN", "message": "Google ID token is required"}
    user = _build_user(1, "google.user@example.com", "googleuser", "premium", 100)
    tokens = {
        "access_token": "google_mock_access_token",
        "refresh_token": "google_mock_refresh_token",
        "token_type": "Bearer",
        "expires_in": 3600,
    }
    return user, tokens, None
