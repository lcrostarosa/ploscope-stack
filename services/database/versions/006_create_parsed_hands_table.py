"""create_parsed_hands_table

Revision ID: 006
Revises: 005
Create Date: 2025-07-22 14:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "006"
down_revision = "005"
branch_labels = None
depends_on = None


def upgrade():
    # Create parsed_hands table
    op.create_table(
        "parsed_hands",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("hand_history_id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("hand_id", sa.String(length=100), nullable=False),
        sa.Column("table_name", sa.String(length=100), nullable=True),
        sa.Column("game_type", sa.String(length=50), nullable=False),
        sa.Column("stakes", sa.String(length=20), nullable=True),
        sa.Column("hand_datetime", sa.DateTime(), nullable=False),
        sa.Column("hero_seat", sa.Integer(), nullable=True),
        sa.Column("hero_cards", sa.JSON(), nullable=True),
        sa.Column("board_cards", sa.JSON(), nullable=True),
        sa.Column("players", sa.JSON(), nullable=False),
        sa.Column("actions", sa.JSON(), nullable=True),
        sa.Column("pot_size", sa.Double(), nullable=True),
        sa.Column("hero_result", sa.Double(), nullable=True),
        sa.Column("showdown_reached", sa.Boolean(), nullable=True),
        sa.Column("hero_equity", sa.Double(), nullable=True),
        sa.Column("expected_value", sa.Double(), nullable=True),
        sa.Column("equity_realization", sa.Double(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(
            ["hand_history_id"],
            ["hand_histories.id"],
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    # Create indexes
    op.create_index("idx_parsed_hands_hand_history_id", "parsed_hands", ["hand_history_id"])
    op.create_index("idx_parsed_hands_user_id", "parsed_hands", ["user_id"])
    op.create_index("idx_parsed_hands_hand_datetime", "parsed_hands", ["hand_datetime"])


def downgrade():
    # Drop indexes
    op.drop_index("idx_parsed_hands_hand_datetime", table_name="parsed_hands")
    op.drop_index("idx_parsed_hands_user_id", table_name="parsed_hands")
    op.drop_index("idx_parsed_hands_hand_history_id", table_name="parsed_hands")

    # Drop table
    op.drop_table("parsed_hands")
