"""create_solver_solutions_table

Revision ID: 007
Revises: 006
Create Date: 2025-07-22 14:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "007"
down_revision = "006"
branch_labels = None
depends_on = None


def upgrade():
    # Create solver_solutions table
    op.create_table(
        "solver_solutions",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("game_state", sa.JSON(), nullable=False),
        sa.Column("solution", sa.JSON(), nullable=False),
        sa.Column("iterations", sa.Integer(), nullable=False, default=1000),
        sa.Column("solve_time", sa.Double(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    # Create indexes
    op.create_index("idx_solver_solutions_user_id", "solver_solutions", ["user_id"])


def downgrade():
    # Drop indexes
    op.drop_index("idx_solver_solutions_user_id", table_name="solver_solutions")

    # Drop table
    op.drop_table("solver_solutions")
