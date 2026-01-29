import React, { ChangeEvent, FormEvent, useState } from 'react';

import { useAuth } from '../../contexts/AuthContext';
import { useFormTracking } from '../../hooks/useAnalytics';
import type { LoginProps } from '../../types/ComponentTypes';
import { getErrorMessage } from '../../types/ErrorTypes';
import './Forms.scss';

const Login: React.FC<LoginProps> = ({ onClose, onSwitchToRegister }) => {
  const { login } = useAuth();
  const [formData, setFormData] = useState<{ email: string; password: string }>(
    {
      email: '',
      password: '',
    }
  );
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [isSuccess, setIsSuccess] = useState(false);
  const { trackFormStart, trackFormSubmit, trackFieldChange } =
    useFormTracking('login');

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
    trackFieldChange(name, value);

    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: '',
      }));
    }
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.email) {
      newErrors.email = 'Email or username is required';
    }

    if (!formData.password) {
      newErrors.password = 'Password is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    trackFormStart();

    if (!validateForm()) {
      trackFormSubmit(false, ['validation_error']);
      return;
    }

    setLoading(true);
    setMessage('');

    try {
      const result = await login(formData.email, formData.password);

      if (result.success) {
        setMessage('Welcome back to PLOScope!');
        setIsSuccess(true);
        trackFormSubmit(true, []);
      } else {
        setErrors({ general: String(result.error ?? 'Login failed') });
        trackFormSubmit(false, [String(result.error ?? 'login_failed')]);
      }
    } catch (error) {
      const errMsg =
        getErrorMessage(error) || 'Login failed. Please try again.';
      setErrors({ general: errMsg });
      trackFormSubmit(false, [errMsg || 'login_failed']);
    } finally {
      setLoading(false);
    }
  };

  const handleContinue = () => {
    if (onClose) {
      onClose();
    }
  };

  // If login is successful, show success state
  if (isSuccess) {
    return (
      <div className="auth-container">
        <div className="auth-card">
          <div className="auth-header">
            <div className="success-icon">✓</div>
            <h2>Welcome Back!</h2>
            <p>You have successfully signed in</p>
          </div>

          <div className="success-content">
            <p className="success-message-large">{message}</p>
            <p className="success-description">
              Ready to continue analyzing poker hands and managing your spots.
            </p>

            <button className="auth-button primary" onClick={handleContinue}>
              Continue to PLOScope
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="auth-container">
      <div className="auth-card">
        <div className="auth-header">
          <h2>Welcome Back</h2>
          <p>Sign in to your account</p>
        </div>

        <form onSubmit={handleSubmit} className="auth-form">
          {errors.general && (
            <div className="error-message general-error">{errors.general}</div>
          )}

          {message && <div className="success-message">{message}</div>}

          <div className="form-group">
            <label htmlFor="email">Email or Username</label>
            <input
              type="text"
              id="email"
              name="email"
              value={formData.email}
              onChange={handleChange}
              className={errors.email ? 'error' : ''}
              placeholder="Enter your email or username"
              disabled={loading}
            />
            {errors.email && (
              <span className="error-message">{errors.email}</span>
            )}
          </div>

          <div className="form-group">
            <label htmlFor="password">Password</label>
            <input
              type="password"
              id="password"
              name="password"
              value={formData.password}
              onChange={handleChange}
              className={errors.password ? 'error' : ''}
              placeholder="Enter your password"
              disabled={loading}
            />
            {errors.password && (
              <span className="error-message">{errors.password}</span>
            )}
          </div>

          <button
            type="submit"
            className="auth-button primary"
            disabled={loading}
          >
            {loading ? 'Signing In...' : 'Sign In'}
          </button>
        </form>

        <div className="auth-footer">
          <p>
            Don&apos;t have an account?{' '}
            <button
              type="button"
              className="link-button"
              onClick={onSwitchToRegister}
              disabled={loading}
            >
              Sign up
            </button>
          </p>
        </div>
      </div>
    </div>
  );
};

export default Login;
