import React, { ChangeEvent, FormEvent, useState } from 'react';

import { useAuth } from '../../contexts/AuthContext';
import { useFormTracking } from '../../hooks/useAnalytics';
import './Forms.scss';

type RegisterProps = { onSwitchToLogin: () => void; onClose?: () => void };

const Register: React.FC<RegisterProps> = ({ onSwitchToLogin, onClose }) => {
  const [formData, setFormData] = useState<{
    email: string;
    username: string;
    first_name: string;
    last_name: string;
    password: string;
    confirmPassword: string;
    accept_terms: boolean;
  }>({
    email: '',
    username: '',
    first_name: '',
    last_name: '',
    password: '',
    confirmPassword: '',
    accept_terms: false,
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [isSuccess, setIsSuccess] = useState(false);
  const [message, setMessage] = useState('');
  const { register } = useAuth();
  const { trackFormStart, trackFormSubmit, trackFieldChange } =
    useFormTracking('register');

  const handleInputChange = (e: ChangeEvent<HTMLInputElement>) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value,
    }));
    trackFieldChange(name, value);
  };

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    trackFormStart();
    setIsLoading(true);
    setError('');

    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      setIsLoading(false);
      trackFormSubmit(false, ['password_mismatch']);
      return;
    }

    if (!formData.accept_terms) {
      setError(
        'You must accept the Terms of Service and Privacy Policy to continue'
      );
      setIsLoading(false);
      trackFormSubmit(false, ['terms_not_accepted']);
      return;
    }

    try {
      const userData = {
        email: formData.email,
        username: formData.username,
        first_name: formData.first_name,
        last_name: formData.last_name,
        password: formData.password,
        accept_terms: formData.accept_terms,
      };

      const result = await register(userData);
      if (result.success) {
        trackFormSubmit(true, []);
        setIsSuccess(true);
        setMessage(result.message || 'Welcome to PLOScope!');
      } else {
        if (result.error === 'signup_limit_reached') {
          // Redirect to waitlist flow
          try {
            await fetch('/api/auth/waitlist', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                email: formData.email,
                username: formData.username,
                first_name: formData.first_name,
                last_name: formData.last_name,
              }),
            });
            setError(
              'Signups are currently limited. You have been added to the waitlist.'
            );
          } catch (e: any) {
            setError(
              'Signups are limited. Please join the waitlist via our contact form.'
            );
          }
        } else {
          setError(result.error || 'Registration failed');
        }
        trackFormSubmit(false, [result.error || 'registration_failed']);
      }
    } catch (err: any) {
      setError(err?.message || 'Registration failed');
      trackFormSubmit(false, [err?.message || 'registration_failed']);
    } finally {
      setIsLoading(false);
    }
  };

  const handleContinue = () => {
    if (onClose) {
      onClose();
    }
  };

  if (isSuccess) {
    return (
      <div className="auth-container">
        <div className="auth-card">
          <div className="auth-header">
            <div className="success-icon">✓</div>
            <h2>Account Created</h2>
            <p>Welcome to PLOScope</p>
          </div>

          <div className="success-content">
            <p className="success-message-large">{message}</p>
            <p className="success-description">
              Your account has been created successfully. You can now start
              using PLOScope.
            </p>

            <button className="auth-button primary" onClick={handleContinue}>
              Continue
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
          <h2>Create Account</h2>
          <p>Sign up to get started with PLOScope</p>
        </div>

        <form onSubmit={handleSubmit} className="auth-form" role="form">
          {error && <div className="error-message">{error}</div>}
          <div className="form-group">
            <label htmlFor="email">Email:</label>
            <input
              type="email"
              id="email"
              name="email"
              value={formData.email}
              onChange={handleInputChange}
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="username">Username:</label>
            <input
              type="text"
              id="username"
              name="username"
              value={formData.username}
              onChange={handleInputChange}
              required
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="first_name">First Name:</label>
              <input
                type="text"
                id="first_name"
                name="first_name"
                value={formData.first_name}
                onChange={handleInputChange}
              />
            </div>

            <div className="form-group">
              <label htmlFor="last_name">Last Name:</label>
              <input
                type="text"
                id="last_name"
                name="last_name"
                value={formData.last_name}
                onChange={handleInputChange}
              />
            </div>
          </div>

          <div className="form-group">
            <label htmlFor="password">Password:</label>
            <input
              type="password"
              id="password"
              name="password"
              value={formData.password}
              onChange={handleInputChange}
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="confirmPassword">Confirm Password:</label>
            <input
              type="password"
              id="confirmPassword"
              name="confirmPassword"
              value={formData.confirmPassword}
              onChange={handleInputChange}
              required
            />
          </div>

          <div className="form-group checkbox-group">
            <input
              type="checkbox"
              id="accept_terms"
              name="accept_terms"
              checked={formData.accept_terms}
              onChange={handleInputChange}
              required
            />
            <label htmlFor="accept_terms" className="checkbox-label">
              <span className="checkbox-text">
                I accept the{' '}
                <a
                  href="/terms"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="legal-link"
                >
                  Terms of Service
                </a>{' '}
                and{' '}
                <a
                  href="/privacy"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="legal-link"
                >
                  Privacy Policy
                </a>
              </span>
            </label>
          </div>

          <button
            type="submit"
            className="auth-button primary"
            disabled={isLoading}
          >
            {isLoading ? 'Registering...' : 'Register'}
          </button>
        </form>

        <div className="auth-footer">
          <p>
            Already have an account?{' '}
            <button
              type="button"
              onClick={onSwitchToLogin}
              className="link-button"
            >
              Login here
            </button>
          </p>
        </div>
      </div>
    </div>
  );
};

export default Register;
