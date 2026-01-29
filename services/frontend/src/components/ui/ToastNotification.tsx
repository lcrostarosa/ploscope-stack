import React, { useState, useEffect, createContext, useContext } from 'react';

// Toast Context
type ToastType = 'success' | 'error' | 'warning' | 'info' | 'loading';
type Toast = { id: number; message: string; type: ToastType; duration: number };
type ToastContextValue = {
  toasts: Toast[];
  addToast: (message: string, type?: ToastType, duration?: number) => number;
  removeToast: (id: number) => void;
  success: (message: string, duration?: number) => number;
  error: (message: string, duration?: number) => number;
  warning: (message: string, duration?: number) => number;
  info: (message: string, duration?: number) => number;
  loading: (message: string) => number;
};
const ToastContext = createContext<ToastContextValue | null>(null);

export const useToast = () => {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used within a ToastProvider');
  }
  return context;
};

// Toast Provider
export const ToastProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const addToast = (
    message: string,
    type: ToastType = 'info',
    duration = 5000
  ) => {
    const id = Date.now() + Math.random();
    const toast = { id, message, type, duration };

    setToasts(prev => [...prev, toast]);

    // Auto remove after duration
    if (duration > 0) {
      setTimeout(() => {
        removeToast(id);
      }, duration);
    }

    return id;
  };

  const removeToast = (id: number) => {
    setToasts(prev => prev.filter(toast => toast.id !== id));
  };

  const value = {
    toasts,
    addToast,
    removeToast,
    // Convenience methods
    success: (message: string, duration?: number) =>
      addToast(message, 'success', duration),
    error: (message: string, duration?: number) =>
      addToast(message, 'error', duration),
    warning: (message: string, duration?: number) =>
      addToast(message, 'warning', duration),
    info: (message: string, duration?: number) =>
      addToast(message, 'info', duration),
    loading: (message: string) => addToast(message, 'loading', 0), // No auto-dismiss
  };

  return (
    <ToastContext.Provider value={value}>
      {children}
      <ToastContainer />
    </ToastContext.Provider>
  );
};

// Toast Container Component
const ToastContainer: React.FC = () => {
  const { toasts } = useToast();

  if (toasts.length === 0) return null;

  return (
    <div className="toast-container dark">
      {toasts.map(toast => (
        <ToastItem key={toast.id} toast={toast} />
      ))}
    </div>
  );
};

// Individual Toast Item
const ToastItem: React.FC<{ toast: Toast }> = ({ toast }) => {
  const { removeToast } = useToast();
  const [isExiting, setIsExiting] = useState(false);

  useEffect(() => {
    // Handle exit animation
    const handleExit = () => {
      setIsExiting(true);
      setTimeout(() => removeToast(toast.id), 300);
    };

    // Auto-dismiss for non-loading toasts
    if (toast.duration > 0) {
      const timer = setTimeout(handleExit, toast.duration - 300);
      return () => clearTimeout(timer);
    }
  }, [toast.id, toast.duration, removeToast]);

  const getToastIcon = (type: ToastType) => {
    const icons = {
      success: '✅',
      error: '❌',
      warning: '⚠️',
      info: 'ℹ️',
      loading: '⏳',
    };
    return icons[type] || icons.info;
  };

  const getToastColor = (type: ToastType) => {
    const colors = {
      success: 'bg-green-800 border-green-600 text-green-100',
      error: 'bg-red-800 border-red-600 text-red-100',
      warning: 'bg-yellow-800 border-yellow-600 text-yellow-100',
      info: 'bg-blue-800 border-blue-600 text-blue-100',
      loading: 'bg-gray-800 border-gray-600 text-gray-100',
    };
    return colors[type] || colors.info;
  };

  return (
    <div
      className={`toast-item ${getToastColor(toast.type)} ${isExiting ? 'toast-exit' : 'toast-enter'}`}
      role="alert"
      aria-live="polite"
    >
      <div className="toast-content">
        <span className="toast-icon" role="img" aria-label={toast.type}>
          {getToastIcon(toast.type)}
        </span>
        <span className="toast-message">{toast.message}</span>
      </div>

      {toast.type !== 'loading' && (
        <button
          onClick={() => removeToast(toast.id)}
          className="toast-close"
          aria-label="Close notification"
        >
          ✕
        </button>
      )}

      {toast.type === 'loading' && (
        <div className="toast-spinner">
          <div className="spinner-ring"></div>
        </div>
      )}
    </div>
  );
};

export default ToastProvider;
