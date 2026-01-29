// UI component types
import type { HTMLAttributes } from 'react';

export type ToastType = 'success' | 'error' | 'warning' | 'info' | 'loading';

export interface Toast {
  id: number;
  message: string;
  type: ToastType;
  duration: number;
}

export interface ToastContextValue {
  toasts: Toast[];
  addToast: (message: string, type: ToastType, duration?: number) => void;
  removeToast: (id: number) => void;
  clearAllToasts: () => void;
}

export type SubscriptionTier = 'free' | 'pro' | 'elite' | string;

export interface TierInfo {
  name: string;
  color: string;
  icon: string;
  canUpgrade: boolean;
}

export interface TierIndicatorProps {
  user?: { subscription_tier?: SubscriptionTier } | null;
  className?: string;
  hideUpgradeButton?: boolean;
}

export type OnboardingCompletePayload = {
  skipped: boolean;
  completedStep: number;
};

export type SpinnerSize = 'small' | 'medium' | 'large';

export interface LoadingSpinnerProps extends HTMLAttributes<HTMLDivElement> {
  size?: SpinnerSize;
  text?: string;
  textColor?: string;
  color?: string;
  className?: string;
}

export interface BreakdownMetrics {
  wins: number;
  ties: number;
  losses: number;
  total: number;
}

export type HandBreakdown = Record<string, number | Partial<BreakdownMetrics>>;

export interface HandBreakdownTableProps {
  breakdown: HandBreakdown;
  title: string;
  context: 'hero' | 'opponents';
  className?: string;
}

export interface HandBreakdownChartProps {
  breakdown: HandBreakdown;
  title: string;
  context: 'hero' | 'opponents';
  className?: string;
}

export interface ConfirmDialogProps {
  isOpen: boolean;
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm: () => void;
  onCancel: () => void;
  type?: 'danger' | 'warning' | 'info';
}

export interface CardProps {
  card: string;
  onClick?: () => void;
  isClickable?: boolean;
  hidden?: boolean;
}

export interface AuthErrorModalProps {
  isOpen: boolean;
  onClose: () => void;
  error?: string;
  title?: string;
}
