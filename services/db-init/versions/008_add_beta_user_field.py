"""add_beta_user_field

Revision ID: 008
Revises: 007
Create Date: 2025-07-22 15:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "008"
down_revision = "007"
branch_labels = None
depends_on = None


def upgrade():
    # Add is_beta_user column to users table
    op.add_column("users", sa.Column("is_beta_user", sa.Boolean(), nullable=True))


def downgrade():
    # Remove is_beta_user column from users table
    op.drop_column("users", "is_beta_user")
