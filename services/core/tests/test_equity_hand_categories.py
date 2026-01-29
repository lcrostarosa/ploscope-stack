import json


def test_hand_categories_real_cards(client):
    """
    Regression: verify categories match expected for specific hands/boards.
    Player: Qd 4c 6c Kc
    Top board: Th Ah 8c => High Card
    Bottom board: Jc Ac 2c => Flush (clubs)
    """
    body = {
        "players": [{"player_number": 1, "cards": ["Qd", "4c", "6c", "Kc"]}],
        "topBoard": ["Th", "Ah", "8c"],
        "bottomBoard": ["Jc", "Ac", "2c"],
        "quick_mode": True,
        "num_iterations": 100,
    }

    resp = client.post("/api/simulated-equity", data=json.dumps(body), content_type="application/json")
    assert resp.status_code == 200
    data = resp.get_json()
    assert isinstance(data, list) and len(data) >= 1
    result = data[0]

    assert result["top_hand_category"] in ("High Card", "high_card", "High card")
    assert "flush" in result["bottom_hand_category"].lower()


def test_no_false_full_house_on_flush_board(client):
    """Bottom board 5s Qs 2s with hole Ad 6s 3d 3s should not be Full House."""
    body = {
        "players": [{"player_number": 1, "cards": ["Ad", "6s", "3d", "3s"]}],
        "topBoard": ["2h", "3c", "4d"],
        "bottomBoard": ["5s", "Qs", "2s"],
        "quick_mode": True,
        "num_iterations": 100,
    }

    resp = client.post("/api/simulated-equity", data=json.dumps(body), content_type="application/json")
    assert resp.status_code == 200
    data = resp.get_json()
    assert isinstance(data, list) and len(data) >= 1
    result = data[0]

    assert result["bottom_hand_category"].lower() not in {
        "full house",
        "full house (top)",
    }
