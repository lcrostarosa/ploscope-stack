"""create_users_table

Revision ID: 001
Revises:
Create Date: 2025-07-22 13:53:51.579381

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # Create users table with all necessary columns
    op.create_table(
        "users",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("username", sa.String(length=80), nullable=True),
        sa.Column("password_hash", sa.String(length=128), nullable=True),
        sa.Column("first_name", sa.String(length=100), nullable=True),
        sa.Column("last_name", sa.String(length=100), nullable=True),
        sa.Column("google_id", sa.String(length=255), nullable=True),
        sa.Column("facebook_id", sa.String(length=255), nullable=True),
        sa.Column("profile_picture", sa.String(length=500), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=True),
        sa.Column("email_verified", sa.Boolean(), nullable=True),
        sa.Column("is_admin", sa.Boolean(), nullable=True),
        sa.Column("subscription_tier", sa.String(length=20), nullable=True),
        sa.Column("stripe_customer_id", sa.String(length=255), nullable=True),
        sa.Column("stripe_subscription_id", sa.String(length=255), nullable=True),
        sa.Column("subscription_status", sa.String(length=20), nullable=True),
        sa.Column("subscription_current_period_end", sa.DateTime(), nullable=True),
        sa.Column("subscription_cancel_at_period_end", sa.Boolean(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.Column("last_login", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    # Create indexes
    op.create_index("ix_users_email", "users", ["email"], unique=True)
    op.create_index("ix_users_username", "users", ["username"], unique=True)
    op.create_index("ix_users_google_id", "users", ["google_id"], unique=True)
    op.create_index("ix_users_facebook_id", "users", ["facebook_id"], unique=True)


def downgrade():
    # Drop indexes
    op.drop_index("ix_users_facebook_id", table_name="users")
    op.drop_index("ix_users_google_id", table_name="users")
    op.drop_index("ix_users_username", table_name="users")
    op.drop_index("ix_users_email", table_name="users")

    # Drop table
    op.drop_table("users")
