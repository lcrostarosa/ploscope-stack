// Card Type System for PLO Solver
// This provides type safety for all card-related operations

// Basic card types
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
export type SuitShort = 'h' | 'd' | 's' | 'c';
export type SuitEmoji = '♥' | '♦' | '♠' | '♣';

// Card formats
export type CardShort = `${Rank}${SuitShort}`; // e.g., 'As', 'Kh', 'Td', '2c'
export type CardEmoji = `${Rank}${SuitEmoji}`; // e.g., 'A♠', 'K♥', 'T♦', '2♣'

// Union type for any valid card format
export type Card = CardShort | CardEmoji;

// Special card values
export type RandomCard = 'RANDOM';
export type EmptyCard = '';
export type CardValue = Card | RandomCard | EmptyCard;

// Card arrays
export type CardArray = CardValue[];
export type CardArray4 = [CardValue, CardValue, CardValue, CardValue]; // For hole cards
export type CardArray3 = [CardValue, CardValue, CardValue]; // For flops
export type CardArray5 = [
  CardValue,
  CardValue,
  CardValue,
  CardValue,
  CardValue,
]; // For complete boards

// Board structure
export interface BoardCards {
  flop: CardArray3;
  turn: CardValue;
  river: CardValue;
}

// Player cards
export interface PlayerCards {
  holeCards: CardArray4;
  stack?: number;
  position?: string;
  isFolded?: boolean;
}

// Community cards for double board games
export interface CommunityCards {
  topBoard: BoardCards;
  bottomBoard: BoardCards;
}

// Card picker metadata
export interface CardPickerMeta {
  type: 'hero' | 'opponent' | 'community' | 'folded';
  index?: number;
  oppIndex?: number;
  cardIndex?: number;
  board?:
    | 'topFlop'
    | 'topTurn'
    | 'topRiver'
    | 'bottomFlop'
    | 'bottomTurn'
    | 'bottomRiver';
  position?: number;
  isNewCard?: boolean;
}

// Card validation
export interface CardValidation {
  isValid: boolean;
  errors: string[];
  warnings: string[];
}

// Card utility functions type definitions
export interface CardUtils {
  isValidCard: (card: string) => boolean;
  convertToShort: (card: string) => CardShort;
  convertToEmoji: (card: string) => CardEmoji;
  getRank: (card: Card) => Rank;
  getSuit: (card: Card) => SuitShort;
  getSuitEmoji: (card: Card) => SuitEmoji;
  isRandom: (card: CardValue) => boolean;
  isEmpty: (card: CardValue) => boolean;
  isFilled: (card: CardValue) => boolean;
  getUsedCards: (cards: CardArray) => Set<Card>;
  getAvailableCards: (usedCards: Set<Card>) => Card[];
  generateRandomCards: (count: number, usedCards?: Set<Card>) => Card[];
}

// Card state management
export interface CardState {
  heroCards: CardArray4;
  opponentCards: CardArray4[];
  communityCards: CommunityCards;
  foldedCards: CardArray;
  foldedStates: {
    topBoard: boolean;
    bottomBoard: boolean;
    opponents: boolean[];
  };
}

// Card picker state
export interface CardPickerState {
  isOpen: boolean;
  type: CardPickerMeta['type'] | null;
  meta: CardPickerMeta;
  availableCards: Card[];
}

// Card validation rules
export interface CardValidationRules {
  requireAllHeroCards: boolean;
  allowPartialOpponents: boolean;
  requireCommunityCards: boolean;
  maxOpponents: number;
  maxTotalCards: number;
}

// Card analysis results
export interface CardAnalysis {
  totalCardsUsed: number;
  remainingCards: number;
  playerCount: number;
  knownPlayers: number;
  randomPlayers: number;
  isComplete: boolean;
  validation: CardValidation;
}

// Card class for advanced operations
export class CardType {
  private value: CardValue;

  constructor(card: CardValue = '') {
    this.value = card;
  }

  // Factory methods
  static create(card: CardValue): CardType {
    return new CardType(card);
  }

  static createRandom(): CardType {
    return new CardType('RANDOM');
  }

  static createEmpty(): CardType {
    return new CardType('');
  }

  // Getters
  getValue(): CardValue {
    return this.value;
  }

  getRank(): Rank | null {
    if (this.isValidCard()) {
      return this.value[0] as Rank;
    }
    return null;
  }

  getSuit(): SuitShort | null {
    if (this.isValidCard()) {
      const suit = this.value[1];
      if (suit === 'h' || suit === 'd' || suit === 's' || suit === 'c') {
        return suit;
      }
    }
    return null;
  }

  getSuitEmoji(): SuitEmoji | null {
    const suit = this.getSuit();
    if (suit) {
      switch (suit) {
        case 'h':
          return '♥';
        case 'd':
          return '♦';
        case 's':
          return '♠';
        case 'c':
          return '♣';
      }
    }
    return null;
  }

  // Validation methods
  isValidCard(): boolean {
    return (
      this.value !== '' && this.value !== 'RANDOM' && this.value.length === 2
    );
  }

  isRandom(): boolean {
    return this.value === 'RANDOM';
  }

  isEmpty(): boolean {
    return this.value === '';
  }

  isFilled(): boolean {
    return this.isValidCard();
  }

  // Conversion methods
  toShort(): CardShort | null {
    if (this.isValidCard()) {
      return this.value as CardShort;
    }
    return null;
  }

  toEmoji(): CardEmoji | null {
    if (this.isValidCard()) {
      const rank = this.getRank();
      const suitEmoji = this.getSuitEmoji();
      if (rank && suitEmoji) {
        return `${rank}${suitEmoji}` as CardEmoji;
      }
    }
    return null;
  }

  // Comparison methods
  equals(other: CardType): boolean {
    return this.value === other.value;
  }

  equalsCard(card: CardValue): boolean {
    return this.value === card;
  }

  // Utility methods
  toString(): string {
    return this.value;
  }

  clone(): CardType {
    return new CardType(this.value);
  }
}

// Card array utilities
export class CardArrayUtils {
  static createEmpty4(): CardArray4 {
    return ['', '', '', ''];
  }

  static createRandom4(): CardArray4 {
    return ['RANDOM', 'RANDOM', 'RANDOM', 'RANDOM'];
  }

  static createEmpty3(): CardArray3 {
    return ['', '', ''];
  }

  static createRandom3(): CardArray3 {
    return ['RANDOM', 'RANDOM', 'RANDOM'];
  }

  static isValidCardArray(cards: CardArray): boolean {
    return cards.every(
      card => card === '' || card === 'RANDOM' || card.length === 2
    );
  }

  static getUsedCards(cards: CardArray): Set<Card> {
    return new Set(
      cards.filter(card => card !== '' && card !== 'RANDOM') as Card[]
    );
  }

  static getFilledCards(cards: CardArray): Card[] {
    return cards.filter(card => card !== '' && card !== 'RANDOM') as Card[];
  }

  static getRandomCards(cards: CardArray): number {
    return cards.filter(card => card === 'RANDOM').length;
  }

  static getEmptyCards(cards: CardArray): number {
    return cards.filter(card => card === '').length;
  }

  static isComplete(cards: CardArray): boolean {
    return cards.every(card => card !== '' && card !== 'RANDOM');
  }

  static hasAnyCards(cards: CardArray): boolean {
    return cards.some(card => card !== '' && card !== 'RANDOM');
  }

  static countCards(cards: CardArray): number {
    return cards.filter(card => card !== '' && card !== 'RANDOM').length;
  }
}

// Board utilities
export class BoardUtils {
  static createEmpty(): BoardCards {
    return {
      flop: ['', '', ''],
      turn: '',
      river: '',
    };
  }

  static createRandom(): BoardCards {
    return {
      flop: ['RANDOM', 'RANDOM', 'RANDOM'],
      turn: 'RANDOM',
      river: 'RANDOM',
    };
  }

  static getUsedCards(board: BoardCards): Set<Card> {
    const usedCards = new Set<Card>();

    board.flop.forEach(card => {
      if (card !== '' && card !== 'RANDOM') {
        usedCards.add(card as Card);
      }
    });

    if (board.turn !== '' && board.turn !== 'RANDOM') {
      usedCards.add(board.turn as Card);
    }

    if (board.river !== '' && board.river !== 'RANDOM') {
      usedCards.add(board.river as Card);
    }

    return usedCards;
  }

  static getFilledCards(board: BoardCards): Card[] {
    const filledCards: Card[] = [];

    board.flop.forEach(card => {
      if (card !== '' && card !== 'RANDOM') {
        filledCards.push(card as Card);
      }
    });

    if (board.turn !== '' && board.turn !== 'RANDOM') {
      filledCards.push(board.turn as Card);
    }

    if (board.river !== '' && board.river !== 'RANDOM') {
      filledCards.push(board.river as Card);
    }

    return filledCards;
  }

  static isComplete(board: BoardCards): boolean {
    return (
      board.flop.every(card => card !== '' && card !== 'RANDOM') &&
      board.turn !== '' &&
      board.turn !== 'RANDOM' &&
      board.river !== '' &&
      board.river !== 'RANDOM'
    );
  }

  static hasAnyCards(board: BoardCards): boolean {
    return (
      board.flop.some(card => card !== '' && card !== 'RANDOM') ||
      (board.turn !== '' && board.turn !== 'RANDOM') ||
      (board.river !== '' && board.river !== 'RANDOM')
    );
  }

  static countCards(board: BoardCards): number {
    let count = 0;

    board.flop.forEach(card => {
      if (card !== '' && card !== 'RANDOM') count++;
    });

    if (board.turn !== '' && board.turn !== 'RANDOM') count++;
    if (board.river !== '' && board.river !== 'RANDOM') count++;

    return count;
  }
}

// Note: Types are already exported above, no need to re-export
