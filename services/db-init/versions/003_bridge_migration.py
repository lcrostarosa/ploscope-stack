"""bridge_migration

Revision ID: 003
Revises: 002
Create Date: 2025-07-22 13:59:59.000000

"""
# from alembic import op
# import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "003"
down_revision = "002"
branch_labels = None
depends_on = None


def upgrade():
    # This is a bridge migration to fix the sequence gap
    # No schema changes needed
    pass


def downgrade():
    # No schema changes to revert
    pass
