"""Add async job system

Revision ID: add_async_job_system
Revises: 82a93951111e
Create Date: 2024-01-15 10:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers
revision = "002"
down_revision = "001"
branch_labels = None
depends_on = None


def upgrade():
    # Create user_credits table
    op.create_table(
        "user_credits",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("daily_credits_used", sa.Integer(), nullable=True),
        sa.Column("monthly_credits_used", sa.Integer(), nullable=True),
        sa.Column("daily_reset_date", sa.Date(), nullable=True),
        sa.Column("monthly_reset_date", sa.Date(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    # Create jobs table
    op.create_table(
        "jobs",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column(
            "job_type",
            sa.Enum("SPOT_SIMULATION", "SOLVER_ANALYSIS", name="jobtype"),
            nullable=False,
        ),
        sa.Column(
            "status",
            sa.Enum(
                "QUEUED",
                "PROCESSING",
                "COMPLETED",
                "FAILED",
                "CANCELLED",
                name="jobstatus",
            ),
            nullable=False,
        ),
        sa.Column("input_data", sa.JSON(), nullable=False),
        sa.Column("result_data", sa.JSON(), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("queue_message_id", sa.String(length=255), nullable=True),
        sa.Column("estimated_duration", sa.Integer(), nullable=True),
        sa.Column("actual_duration", sa.Integer(), nullable=True),
        sa.Column("progress_percentage", sa.Integer(), nullable=True),
        sa.Column("progress_message", sa.String(length=255), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("started_at", sa.DateTime(), nullable=True),
        sa.Column("completed_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    # Create indexes for better query performance
    op.create_index("idx_user_credits_user_id", "user_credits", ["user_id"])
    op.create_index("idx_jobs_user_id", "jobs", ["user_id"])
    op.create_index("idx_jobs_status", "jobs", ["status"])
    op.create_index("idx_jobs_job_type", "jobs", ["job_type"])
    op.create_index("idx_jobs_created_at", "jobs", ["created_at"])


def downgrade():
    # Drop indexes
    op.drop_index("idx_jobs_created_at")
    op.drop_index("idx_jobs_job_type")
    op.drop_index("idx_jobs_status")
    op.drop_index("idx_jobs_user_id")
    op.drop_index("idx_user_credits_user_id")

    # Drop tables
    op.drop_table("jobs")
    op.drop_table("user_credits")

    # Drop enums
    op.execute("DROP TYPE IF EXISTS jobtype")
    op.execute("DROP TYPE IF EXISTS jobstatus")
