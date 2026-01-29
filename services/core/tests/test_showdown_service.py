import json


def test_quartering_simple(app, client):
    # Two players, double board; top split, bottom won by player 1 → 75/25 split
    body = {
        "players": [
            {"player_number": 1, "cards": ["Ah", "Ad", "Kc", "Qs"]},
            {"player_number": 2, "cards": ["As", "Ac", "Kd", "Qh"]},
        ],
        "topBoard": ["2h", "7d", "Ts", "3c", "9h"],
        "bottomBoard": ["Kh", "Qd", "Jc", "2c", "3d"],
        "playerInvested": [100, 100],
        "foldedPlayers": [],
    }

    # We expect total pot = 200; split into layers yields one layer of 200
    # top half 100 split (possible tie), bottom half 100 to a single winner
    resp = client.post("/api/resolve-showdown", data=json.dumps(body), content_type="application/json")
    assert resp.status_code == 200
    data = resp.get_json()
    assert "payouts" in data
    assert sum(data["payouts"]) == sum(body["playerInvested"])  # conservation


def test_side_pot_excludes_folded_from_eligibility(app, client):
    # Three players, one folded after investing; folded chips should remain but cannot win
    body = {
        "players": [
            {"player_number": 1, "cards": ["Ah", "Kh", "Qh", "Jh"]},
            {"player_number": 2, "cards": ["Ad", "Kd", "Qd", "Jd"]},
            {"player_number": 3, "cards": ["As", "Ks", "Qs", "Js"]},
        ],
        "topBoard": ["2c", "3c", "4c", "5c", "6c"],
        "bottomBoard": ["2d", "3d", "4d", "5d", "6d"],
        "playerInvested": [50, 50, 50],
        # foldedPlayers are 0-based indices; fold player index 2 (third player)
        "foldedPlayers": [2],
    }

    resp = client.post("/api/resolve-showdown", data=json.dumps(body), content_type="application/json")
    assert resp.status_code == 200
    payouts = resp.get_json()["payouts"]
    # Folded player 3 should receive 0
    assert payouts[2] == 0
    assert sum(payouts) == 150
