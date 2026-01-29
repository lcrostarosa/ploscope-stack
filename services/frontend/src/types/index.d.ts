// Global domain types for the frontend

export type SuitShort = 'h' | 'd' | 's' | 'c';
export type SuitEmoji = '♥' | '♦' | '♠' | '♣';
export type Rank =
  | '2'
  | '3'
  | '4'
  | '5'
  | '6'
  | '7'
  | '8'
  | '9'
  | 'T'
  | 'J'
  | 'Q'
  | 'K'
  | 'A';

export type CardShort = `${Rank}${SuitShort}`;
export type CardEmoji = `${Rank}${SuitEmoji}`;
export type CardString = CardShort | CardEmoji | string;

export interface CardSelectorProps {
  value: CardString;
  onChange: (value: CardString) => void;
  disabled?: boolean;
  placeholder?: string;
  usedCards?: Set<string>;
}

export interface CardProps {
  card: CardString;
  onClick?: () => void;
  isClickable?: boolean;
}

export type LogLevelName = 'error' | 'warn' | 'info' | 'debug';
