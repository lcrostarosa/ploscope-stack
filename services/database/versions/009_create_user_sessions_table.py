"""create_user_sessions_table

Revision ID: 009
Revises: 008
Create Date: 2025-07-22 14:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "009"
down_revision = "008"
branch_labels = None
depends_on = None


def upgrade():
    # Create user_sessions table
    op.create_table(
        "user_sessions",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("token_jti", sa.String(length=255), nullable=False),
        sa.Column("ip_address", sa.String(length=45), nullable=True),
        sa.Column("user_agent", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=True, default=True),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    # Create indexes
    op.create_index("idx_user_sessions_user_id", "user_sessions", ["user_id"])
    op.create_index("idx_user_sessions_token_jti", "user_sessions", ["token_jti"], unique=True)


def downgrade():
    # Drop indexes
    op.drop_index("idx_user_sessions_token_jti", table_name="user_sessions")
    op.drop_index("idx_user_sessions_user_id", table_name="user_sessions")

    # Drop table
    op.drop_table("user_sessions")
