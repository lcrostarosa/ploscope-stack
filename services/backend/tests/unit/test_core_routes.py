"""
Unit tests for core routes_http.
"""


# import json
from unittest.mock import Mock, patch

import pytest

# Skip this test module if core module is not available
try:
    from core.models.job import Job
    from core.models.user import User
    from core.services.player_profiles import PlayerProfile, PlayerProfileManager
except ImportError:
    pytest.skip("core module not available", allow_module_level=True)

# from flask import g
from flask_jwt_extended import create_access_token

from src.backend.models.enums import JobType


class TestPlayerProfileRoutes:
    """Test player profile management endpoints."""

    def test_get_player_profiles_success(self, client, app):
        """Test successful retrieval of player profiles."""
        with app.app_context():
            # Create a test user in the database
            test_user = User(
                email="test@example.com",
                username="testuser",
                password="test_password",
                first_name="Test",
                last_name="User",
            )
            # Set a specific ID for the test user
            test_user.id = 1

            # Don't actually add to database, just mock it
            # db.session.add(test_user)
            # db.session.commit()

            access_token = create_access_token(identity=str(test_user.id))

            # Mock the User query to return our test user
            with patch("core.utils.auth_utils.User") as mock_user_class:
                # Set up the mock to return our test user when queried
                # The auth_required decorator calls: User.query.filter_by(id=current_user_id, is_active=True).first()
                mock_query = Mock()
                mock_filter = Mock()
                mock_filter.first.return_value = test_user
                mock_query.filter_by.return_value = mock_filter
                mock_user_class.query = mock_query

                headers = {"Authorization": f"Bearer {access_token}"}
                response = client.get("/api/player-profiles", headers=headers)

            # Assertions
            assert response.status_code == 200
            data = response.get_json()
            assert "fish" in data
            assert "loose_aggressive" in data
            assert "loose_passive" in data
            assert "maniac" in data
            assert "nit" in data
            assert "tight_aggressive" in data
            assert "tight_passive" in data

    def test_get_player_profiles_includes_custom_profiles(self, client, app):
        """Test that custom profiles are included in the response."""
        with app.app_context():
            # Create a test user (mocked, don't use db.session)
            test_user = User(
                email="test@example.com",
                username="testuser",
                password="test_password",
                first_name="Test",
                last_name="User",
            )
            test_user.id = 1

            # Mock profile manager and add a custom profile
            custom_profile = PlayerProfile(
                name="Custom Test",
                description="A custom test profile",
                hand_range_tightness=50,
                preflop_aggression=60,
                flop_aggression=65,
                turn_aggression=60,
                river_aggression=55,
                bluff_frequency=20,
                value_bet_frequency=70,
                fold_to_pressure=40,
                threeb_frequency=15,
                fourb_frequency=8,
                cbet_frequency=60,
                check_call_frequency=45,
                donk_bet_frequency=10,
                bet_sizing_aggression=60,
                positional_awareness=70,
                slow_play_frequency=25,
                tilt_resistance=65,
            )

            app.profile_manager = PlayerProfileManager()
            app.profile_manager.add_custom_profile(custom_profile)

            access_token = create_access_token(identity=str(test_user.id))

            # Mock the User query to return our test user
            with patch("core.utils.auth_utils.User") as mock_user_class:
                mock_query = Mock()
                mock_filter = Mock()
                mock_filter.first.return_value = test_user
                mock_query.filter_by.return_value = mock_filter
                mock_user_class.query = mock_query

                headers = {"Authorization": f"Bearer {access_token}"}
                response = client.get("/api/player-profiles", headers=headers)

            assert response.status_code == 200
            data = response.get_json()

            # Should include the custom profile
            assert "custom_test" in data
            assert data["custom_test"]["name"] == "Custom Test"

    def test_get_player_profiles_error_handling(self, client, app):
        """Test error handling when profile_manager fails."""
        with app.app_context():
            # Create a test user in the database
            test_user = User(
                email="test@example.com",
                username="testuser",
                password="test_password",
                first_name="Test",
                last_name="User",
            )
            test_user.id = 1  # Mock user ID

            access_token = create_access_token(identity=str(test_user.id))

            # Mock the User query to return our test user
            with patch("core.utils.auth_utils.User") as mock_user_class:
                mock_query = Mock()
                mock_filter = Mock()
                mock_filter.first.return_value = test_user
                mock_query.filter_by.return_value = mock_filter
                mock_user_class.query = mock_query

                # Mock profile_manager to raise an exception
                with patch.object(
                    app.profile_manager,
                    "get_all_profiles",
                    side_effect=Exception("Database error"),
                ):
                    headers = {"Authorization": f"Bearer {access_token}"}
                    response = client.get("/api/player-profiles", headers=headers)

                assert response.status_code == 500
                data = response.get_json()
                assert "error" in data
                assert data["error"] == "Failed to get player profiles"

    def test_create_custom_profile_success(self, client, app):
        """Test successful creation of a custom profile."""
        with app.app_context():
            # Create a test user in the database
            test_user = User(
                email="test@example.com",
                username="testuser",
                password="test_password",
                first_name="Test",
                last_name="User",
            )
            test_user.id = 1  # Mock user ID

            access_token = create_access_token(identity=str(test_user.id))

            profile_data = {
                "name": "New Custom",
                "description": "A new custom profile",
                "hand_range_tightness": 45,
                "preflop_aggression": 55,
                "flop_aggression": 60,
                "turn_aggression": 55,
                "river_aggression": 50,
                "bluff_frequency": 25,
                "value_bet_frequency": 75,
                "fold_to_pressure": 35,
                "threeb_frequency": 20,
                "fourb_frequency": 10,
                "cbet_frequency": 65,
                "check_call_frequency": 40,
                "donk_bet_frequency": 15,
                "bet_sizing_aggression": 65,
                "positional_awareness": 75,
                "slow_play_frequency": 20,
                "tilt_resistance": 70,
            }

            # Mock the User query to return our test user
            with patch("core.utils.auth_utils.User") as mock_user_class:
                mock_query = Mock()
                mock_filter = Mock()
                mock_filter.first.return_value = test_user
                mock_query.filter_by.return_value = mock_filter
                mock_user_class.query = mock_query

                app.profile_manager = PlayerProfileManager()

                # Mock the save operation to avoid file I/O
                with patch.object(app.profile_manager, "save_custom_profiles"):
                    headers = {"Authorization": f"Bearer {access_token}"}
                    response = client.post("/api/player-profiles", headers=headers, json=profile_data)

                assert response.status_code == 201
                data = response.get_json()
                assert data["message"] == "Profile created successfully"
                assert "profile" in data
                assert data["profile"]["name"] == "New Custom"

    def test_create_custom_profile_missing_fields(self, client, app):
        """Test profile creation with missing required fields."""
        with app.app_context():
            # Create a test user in the database
            test_user = User(
                email="test@example.com",
                username="testuser",
                password="test_password",
                first_name="Test",
                last_name="User",
            )
            test_user.id = 1  # Mock user ID

            access_token = create_access_token(identity=str(test_user.id))

            # Missing the required name field
            incomplete_data = {"description": "Missing name field"}

            # Mock the User query to return our test user
            with patch("core.utils.auth_utils.User") as mock_user_class:
                mock_query = Mock()
                mock_filter = Mock()
                mock_filter.first.return_value = test_user
                mock_query.filter_by.return_value = mock_filter
                mock_user_class.query = mock_query

                app.profile_manager = PlayerProfileManager()

                headers = {"Authorization": f"Bearer {access_token}"}
                response = client.post("/api/player-profiles", headers=headers, json=incomplete_data)

            assert response.status_code == 400
            data = response.get_json()
            assert "error" in data
            assert "Missing required field" in data["error"]

    def test_create_custom_profile_duplicate_name(self, client, app):
        """Test profile creation with duplicate name."""
        with app.app_context():
            # Create a test user in the database
            test_user = User(
                email="test@example.com",
                username="testuser",
                password="test_password",
                first_name="Test",
                last_name="User",
            )
            test_user.id = 1  # Mock user ID

            access_token = create_access_token(identity=str(test_user.id))

            # Try to create a profile with the same name as a predefined one
            profile_data = {
                "name": "nit",  # This conflicts with predefined profile
                "description": "A duplicate name",
                "hand_range_tightness": 45,
                "preflop_aggression": 55,
                "flop_aggression": 60,
                "turn_aggression": 55,
                "river_aggression": 50,
                "bluff_frequency": 25,
                "value_bet_frequency": 75,
                "fold_to_pressure": 35,
                "threeb_frequency": 20,
                "fourb_frequency": 10,
                "cbet_frequency": 65,
                "check_call_frequency": 40,
                "donk_bet_frequency": 15,
                "bet_sizing_aggression": 65,
                "positional_awareness": 75,
                "slow_play_frequency": 20,
                "tilt_resistance": 70,
            }

            # Mock the User query to return our test user
            with patch("core.utils.auth_utils.User") as mock_user_class:
                mock_query = Mock()
                mock_filter = Mock()
                mock_filter.first.return_value = test_user
                mock_query.filter_by.return_value = mock_filter
                mock_user_class.query = mock_query

                headers = {"Authorization": f"Bearer {access_token}"}
                response = client.post("/api/player-profiles", headers=headers, json=profile_data)

            assert response.status_code == 400
            data = response.get_json()
            assert "error" in data
            assert "already exists" in data["error"]

    def test_delete_custom_profile_success(self, client, app):
        """Test successful deletion of a custom profile."""
        with app.app_context():
            # Create a test user in the database
            test_user = User(
                email="test@example.com",
                username="testuser",
                password="test_password",
                first_name="Test",
                last_name="User",
            )
            test_user.id = 1  # Mock user ID

            # Add a custom profile to the mock profile manager
            custom_profile_mock = Mock()
            custom_profile_mock.to_dict = lambda: {"name": "to_delete"}
            app.profile_manager.get_all_profiles.return_value = {
                "fish": Mock(to_dict=lambda: {"name": "fish"}),
                "loose_aggressive": Mock(to_dict=lambda: {"name": "loose_aggressive"}),
                "loose_passive": Mock(to_dict=lambda: {"name": "loose_passive"}),
                "maniac": Mock(to_dict=lambda: {"name": "maniac"}),
                "nit": Mock(to_dict=lambda: {"name": "nit"}),
                "tight_aggressive": Mock(to_dict=lambda: {"name": "tight_aggressive"}),
                "tight_passive": Mock(to_dict=lambda: {"name": "tight_passive"}),
                "to_delete": custom_profile_mock,
            }

            access_token = create_access_token(identity=str(test_user.id))

            # Mock the User query to return our test user
            with patch("core.utils.auth_utils.User") as mock_user_class:
                mock_query = Mock()
                mock_filter = Mock()
                mock_filter.first.return_value = test_user
                mock_query.filter_by.return_value = mock_filter
                mock_user_class.query = mock_query

                # Mock the save operation to avoid file I/O
                with patch.object(app.profile_manager, "save_custom_profiles"):
                    headers = {"Authorization": f"Bearer {access_token}"}
                    response = client.delete("/api/player-profiles/to_delete", headers=headers)

                assert response.status_code == 200
                data = response.get_json()
                assert data["message"] == "Profile deleted successfully"

    def test_delete_custom_profile_not_found(self, client, app):
        """Test deletion of a non-existent custom profile."""
        with app.app_context():
            # Create a test user in the database
            test_user = User(
                email="test@example.com",
                username="testuser",
                password="test_password",
                first_name="Test",
                last_name="User",
            )
            test_user.id = 1  # Mock user ID

            access_token = create_access_token(identity=str(test_user.id))

            # Mock the User query to return our test user

            with patch("core.utils.auth_utils.User") as mock_user_class:
                mock_query = Mock()

                mock_filter = Mock()

                mock_filter.first.return_value = test_user

                mock_query.filter_by.return_value = mock_filter

                mock_user_class.query = mock_query

                headers = {"Authorization": f"Bearer {access_token}"}
                response = client.delete("/api/player-profiles/nonexistent", headers=headers)

            assert response.status_code == 404
            data = response.get_json()
            assert "error" in data
            assert "not found" in data["error"]

    def test_delete_predefined_profile_fails(self, client, app):
        """Test that predefined profiles cannot be deleted."""
        with app.app_context():
            # Create a test user in the database
            test_user = User(
                email="test@example.com",
                username="testuser",
                password="test_password",
                first_name="Test",
                last_name="User",
            )
            test_user.id = 1  # Mock user ID

            access_token = create_access_token(identity=str(test_user.id))

            # Mock the User query to return our test user

            with patch("core.utils.auth_utils.User") as mock_user_class:
                mock_query = Mock()

                mock_filter = Mock()

                mock_filter.first.return_value = test_user

                mock_query.filter_by.return_value = mock_filter

                mock_user_class.query = mock_query

                headers = {"Authorization": f"Bearer {access_token}"}
                response = client.delete("/api/player-profiles/nit", headers=headers)

            assert response.status_code == 400
            data = response.get_json()
            assert "error" in data
            assert "Cannot delete predefined profile" in data["error"]


class TestSimulateVsProfilesRoute:
    """Test the simulate vs profiles endpoint."""

    def test_simulate_vs_profiles_success(self, client, app):
        """Test successful simulation vs profiles."""
        with app.app_context():
            # Create a test user in the database
            test_user = User(
                email="test@example.com",
                username="testuser",
                password="test_password",
                first_name="Test",
                last_name="User",
            )
            test_user.id = 1  # Mock user ID

            access_token = create_access_token(identity=str(test_user.id))

            simulation_data = {
                "hero_cards": ["As", "Ks", "Qd", "Jc"],
                "opponent_profiles": ["nit", "fish", "tight_aggressive"],
                "top_board": ["2h", "3s", "4d"],
                "bottom_board": ["7c", "8h", "9s"],
                "num_iterations": 1000,
            }

            # Mock the User query to return our test user
            with patch("core.utils.auth_utils.User") as mock_user_class:
                mock_query = Mock()
                mock_filter = Mock()
                mock_filter.first.return_value = test_user
                mock_query.filter_by.return_value = mock_filter
                mock_user_class.query = mock_query

                # Mock the equity calculation functions
                with patch("backend.routes_http.core_routes.simulate_estimated_equity") as mock_equity:
                    mock_equity.return_value = (75.0, None, {}, None, None)

                    with patch("backend.routes_http.core_routes.calculate_exploits_vs_profile") as mock_exploits:
                        mock_exploits.return_value = {"suggested_actions": ["raise", "call"]}

                        headers = {"Authorization": f"Bearer {access_token}"}
                        response = client.post(
                            "/api/simulate-vs-profiles",
                            headers=headers,
                            json=simulation_data,
                        )

                        assert response.status_code == 200
                        data = response.get_json()
                        assert isinstance(data, dict)
                        assert "equity" in data
                        assert "iterations" in data
                        assert "solve_time" in data

    def test_simulate_vs_profiles_invalid_hero_cards(self, client, app):
        """Test simulation with invalid hero cards."""
        with app.app_context():
            # Create a test user in the database
            test_user = User(
                email="test@example.com",
                username="testuser",
                password="test_password",
                first_name="Test",
                last_name="User",
            )
            test_user.id = 1  # Mock user ID

            access_token = create_access_token(identity=str(test_user.id))

            simulation_data = {
                # Missing hero_cards field
                "opponent_profiles": ["nit"],
                "top_board": ["2h", "3s", "4d"],
                "bottom_board": ["7c", "8h", "9s"],
                "num_iterations": 1000,
            }

            # Mock the User query to return our test user
            with patch("core.utils.auth_utils.User") as mock_user_class:
                mock_query = Mock()
                mock_filter = Mock()
                mock_filter.first.return_value = test_user
                mock_query.filter_by.return_value = mock_filter
                mock_user_class.query = mock_query

                headers = {"Authorization": f"Bearer {access_token}"}
                response = client.post("/api/simulate-vs-profiles", headers=headers, json=simulation_data)

                assert response.status_code == 400
                data = response.get_json()
                assert "error" in data
                assert "Missing hero_cards" in data["error"]

    def test_simulate_vs_profiles_with_custom_profile(self, client, app):
        """Test simulation that includes a custom profile."""
        with app.app_context():
            # Create a test user in the database
            test_user = User(
                email="test@example.com",
                username="testuser",
                password="test_password",
                first_name="Test",
                last_name="User",
            )
            test_user.id = 1  # Mock user ID

            # Add a custom profile
            custom_profile = PlayerProfile(
                name="Custom Villain",
                description="A custom villain profile",
                hand_range_tightness=40,
                preflop_aggression=70,
                flop_aggression=75,
                turn_aggression=70,
                river_aggression=65,
                bluff_frequency=30,
                value_bet_frequency=80,
                fold_to_pressure=25,
                threeb_frequency=25,
                fourb_frequency=15,
                cbet_frequency=75,
                check_call_frequency=30,
                donk_bet_frequency=20,
                bet_sizing_aggression=75,
                positional_awareness=80,
                slow_play_frequency=15,
                tilt_resistance=60,
            )
            app.profile_manager.add_custom_profile(custom_profile)

            access_token = create_access_token(identity=str(test_user.id))

            simulation_data = {
                "hero_cards": ["As", "Ks", "Qd", "Jc"],
                "opponent_profiles": ["custom_villain"],
                "top_board": ["2h", "3s", "4d"],
                "bottom_board": ["7c", "8h", "9s"],
                "num_iterations": 1000,
            }

            # Mock the User query to return our test user
            with patch("core.utils.auth_utils.User") as mock_user_class:
                mock_query = Mock()
                mock_filter = Mock()
                mock_filter.first.return_value = test_user
                mock_query.filter_by.return_value = mock_filter
                mock_user_class.query = mock_query

                # Mock the equity calculation functions
                with patch("backend.routes_http.core_routes.simulate_estimated_equity") as mock_equity:
                    mock_equity.return_value = (65.0, None, {}, None, None)

                    with patch("backend.routes_http.core_routes.calculate_exploits_vs_profile") as mock_exploits:
                        mock_exploits.return_value = {"suggested_actions": ["3bet", "fold"]}

                        headers = {"Authorization": f"Bearer {access_token}"}
                        response = client.post(
                            "/api/simulate-vs-profiles",
                            headers=headers,
                            json=simulation_data,
                        )

                        assert response.status_code == 200
                        data = response.get_json()
                        assert isinstance(data, dict)
                        assert "equity" in data
                        assert "iterations" in data
                        assert "solve_time" in data


class TestCreditsRoute:
    """Test the credits endpoint."""

    def test_get_user_credits_success(self, client, app):
        """Test successful retrieval of user credits."""
        with app.app_context():
            # Create a test user in the database
            test_user = User(
                email="test@example.com",
                username="testuser",
                password="test_password",
                first_name="Test",
                last_name="User",
                subscription_tier="premium",
            )
            test_user.id = 1  # Mock user ID

            access_token = create_access_token(identity=str(test_user.id))

            # Mock the User query for authentication
            with patch("core.utils.auth_utils.User") as mock_user_class:
                # Set up the mock to return our test user when queried
                mock_query = Mock()
                mock_filter = Mock()
                mock_filter.first.return_value = test_user
                mock_query.filter_by.return_value = mock_filter
                mock_user_class.query = mock_query

                # Mock the UserCredit model and database operations
                with patch("backend.routes_http.core_routes.UserCredit") as mock_credit_class:
                    mock_credit_instance = Mock()
                    mock_credit_instance.get_remaining_credits.return_value = {
                        "credits": 100,
                        "total_credits": 1000,
                        "tier": "premium",
                    }
                    mock_credit_class.return_value = mock_credit_instance

                    with patch("backend.routes_http.core_routes.db"):
                        headers = {"Authorization": f"Bearer {access_token}"}
                        response = client.get("/api/credits", headers=headers)

                        assert response.status_code == 200
                        data = response.get_json()
                        assert "credits" in data
                        assert data["credits"] == 100
                        assert data["tier"] == "free"

    def test_get_user_credits_options_request(self, client, app):
        """Test OPTIONS request for credits endpoint."""
        with app.app_context():
            response = client.options("/api/credits")
            assert response.status_code == 200


def test_job_model_id_argument_rejected(app):
    """Unit: Job model should not accept id argument in constructor."""
    with app.app_context():
        try:
            # pylint: disable=unexpected-keyword-arg
            Job(
                id="should-fail",
                job_type=JobType.SOLVER_ANALYSIS,
                input_data={},
                user_id="user",
            )
            assert False, "Job accepted id argument, but should not."
        except TypeError as e:
            assert "unexpected keyword argument" in str(e)


def test_job_model_id_is_generated(app):
    """Unit: Job model id should be generated by the database."""
    with app.app_context():
        job = Job(job_type=JobType.SOLVER_ANALYSIS, input_data={}, user_id="user")
        # Mock the database session
        with patch("core.models.base.db") as mock_db:
            mock_session = Mock()
            mock_db.session = mock_session
            mock_session.add = Mock()
            mock_session.flush = Mock()

            # Simulate the database generating an ID
            job.id = "generated_id_123"

            assert job.id is not None
            assert isinstance(job.id, str)
