"""create_hand_histories_table

Revision ID: 005
Revises: 004
Create Date: 2025-07-22 14:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "005"
down_revision = "004"
branch_labels = None
depends_on = None


def upgrade():
    # Create hand_histories table
    op.create_table(
        "hand_histories",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("filename", sa.String(length=255), nullable=False),
        sa.Column("file_hash", sa.String(length=64), nullable=False),
        sa.Column("poker_site", sa.String(length=50), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=True, default="uploading"),
        sa.Column("total_hands", sa.Integer(), nullable=True),
        sa.Column("processed_hands", sa.Integer(), nullable=True, default=0),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("session_start", sa.DateTime(), nullable=True),
        sa.Column("session_end", sa.DateTime(), nullable=True),
        sa.Column("total_profit", sa.Double(), nullable=True),
        sa.Column("bb_per_100", sa.Double(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    # Create indexes
    op.create_index("idx_hand_histories_user_id", "hand_histories", ["user_id"])
    op.create_index("idx_hand_histories_file_hash", "hand_histories", ["file_hash"], unique=True)


def downgrade():
    # Drop indexes
    op.drop_index("idx_hand_histories_file_hash", table_name="hand_histories")
    op.drop_index("idx_hand_histories_user_id", table_name="hand_histories")

    # Drop table
    op.drop_table("hand_histories")
