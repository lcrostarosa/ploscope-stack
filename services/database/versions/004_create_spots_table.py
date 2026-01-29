"""create_spots_table

Revision ID: 004
Revises: 003
Create Date: 2025-07-22 14:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "004"
down_revision = "003"
branch_labels = None
depends_on = None


def upgrade():
    # Create spots table
    op.create_table(
        "spots",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("top_board", sa.JSON(), nullable=False),
        sa.Column("bottom_board", sa.JSON(), nullable=False),
        sa.Column("players", sa.JSON(), nullable=False),
        sa.Column("simulation_runs", sa.Integer(), nullable=False, default=10000),
        sa.Column("max_hand_combinations", sa.Integer(), nullable=False, default=10000),
        sa.Column("results", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    # Create indexes
    op.create_index("idx_spots_user_id", "spots", ["user_id"])


def downgrade():
    # Drop indexes
    op.drop_index("idx_spots_user_id", table_name="spots")

    # Drop table
    op.drop_table("spots")
