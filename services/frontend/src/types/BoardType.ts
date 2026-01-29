import { generateRandomCards } from '../utils/constants';

export type Street = 'flop' | 'turn' | 'river';
export type BoardNumber = 1 | 2;

export interface BoardCards {
  flop: string[];
  turn: string;
  river: string;
}

export class BoardType {
  private flop: string[];
  private turn: string;
  private river: string;

  constructor(
    flop: string[] = ['', '', ''],
    turn: string = '',
    river: string = ''
  ) {
    this.flop = [...flop];
    this.turn = turn;
    this.river = river;
  }

  // Factory methods
  static createEmpty(): BoardType {
    return new BoardType();
  }

  static createFromCards(
    flop: string[],
    turn: string = '',
    river: string = ''
  ): BoardType {
    return new BoardType(flop, turn, river);
  }

  static createFromBoardCards(boardCards: BoardCards): BoardType {
    return new BoardType(boardCards.flop, boardCards.turn, boardCards.river);
  }

  // Getters
  getFlop(): string[] {
    return [...this.flop];
  }

  getTurn(): string {
    return this.turn;
  }

  getRiver(): string {
    return this.river;
  }

  getCard(street: Street, index?: number): string {
    switch (street) {
      case 'flop':
        return index !== undefined ? this.flop[index] || '' : '';
      case 'turn':
        return this.turn;
      case 'river':
        return this.river;
      default:
        return '';
    }
  }

  getAllCards(): string[] {
    return [
      ...this.flop.filter(card => card),
      ...(this.turn ? [this.turn] : []),
      ...(this.river ? [this.river] : []),
    ];
  }

  getCardsForStreet(street: Street): string[] {
    switch (street) {
      case 'flop':
        return this.getFlop();
      case 'turn':
        return this.turn ? [this.turn] : [];
      case 'river':
        return this.river ? [this.river] : [];
      default:
        return [];
    }
  }

  // Setters
  setFlop(flop: string[]): void {
    this.flop = [...flop];
  }

  setTurn(turn: string): void {
    this.turn = turn;
  }

  setRiver(river: string): void {
    this.river = river;
  }

  setCard(street: Street, card: string, index?: number): void {
    switch (street) {
      case 'flop':
        if (index !== undefined && index >= 0 && index < this.flop.length) {
          this.flop[index] = card;
        }
        break;
      case 'turn':
        this.turn = card;
        break;
      case 'river':
        this.river = card;
        break;
    }
  }

  // Utility methods
  clear(): void {
    this.flop = ['', '', ''];
    this.turn = '';
    this.river = '';
  }

  clearStreet(street: Street): void {
    switch (street) {
      case 'flop':
        this.flop = ['', '', ''];
        break;
      case 'turn':
        this.turn = '';
        break;
      case 'river':
        this.river = '';
        break;
    }
  }

  isEmpty(): boolean {
    return this.flop.every(card => !card) && !this.turn && !this.river;
  }

  isStreetComplete(street: Street): boolean {
    switch (street) {
      case 'flop':
        return this.flop.every(card => card && card !== '');
      case 'turn':
        return !!this.turn;
      case 'river':
        return !!this.river;
      default:
        return false;
    }
  }

  getCurrentStreet(): Street {
    if (this.river) return 'river';
    if (this.turn) return 'turn';
    if (this.flop.some(card => card)) return 'flop';
    return 'flop'; // Default to flop even if empty
  }

  getCardCount(): number {
    return this.getAllCards().length;
  }

  // Randomization methods
  randomize(usedCards: Set<string> = new Set(), street: Street = 'flop'): void {
    if (street === 'flop' || street === 'turn' || street === 'river') {
      // Randomize flop
      const newFlop = generateRandomCards(3, usedCards);
      this.setFlop(newFlop);
      newFlop.forEach(card => usedCards.add(card));
    }

    if (street === 'turn' || street === 'river') {
      // Randomize turn
      const newTurn = generateRandomCards(1, usedCards)[0];
      this.setTurn(newTurn);
      usedCards.add(newTurn);
    }

    if (street === 'river') {
      // Randomize river
      const newRiver = generateRandomCards(1, usedCards)[0];
      this.setRiver(newRiver);
    }
  }

  randomizeStreet(street: Street, usedCards: Set<string> = new Set()): void {
    switch (street) {
      case 'flop': {
        const newFlop = generateRandomCards(3, usedCards);
        this.setFlop(newFlop);
        newFlop.forEach(card => usedCards.add(card));
        break;
      }
      case 'turn': {
        const newTurn = generateRandomCards(1, usedCards)[0];
        this.setTurn(newTurn);
        usedCards.add(newTurn);
        break;
      }
      case 'river': {
        const newRiver = generateRandomCards(1, usedCards)[0];
        this.setRiver(newRiver);
        usedCards.add(newRiver);
        break;
      }
    }
  }

  // Validation methods
  isValid(): boolean {
    // Check for duplicate cards
    const allCards = this.getAllCards();
    const uniqueCards = new Set(allCards);
    return allCards.length === uniqueCards.size;
  }

  hasDuplicates(): boolean {
    return !this.isValid();
  }

  // Conversion methods
  toBoardCards(): BoardCards {
    return {
      flop: [...this.flop],
      turn: this.turn,
      river: this.river,
    };
  }

  toArray(): string[] {
    return this.getAllCards();
  }

  // Clone method
  clone(): BoardType {
    return new BoardType([...this.flop], this.turn, this.river);
  }

  // Comparison methods
  equals(other: BoardType): boolean {
    return (
      JSON.stringify(this.flop) === JSON.stringify(other.flop) &&
      this.turn === other.turn &&
      this.river === other.river
    );
  }

  // String representation
  toString(): string {
    const cards = this.getAllCards();
    return cards.length > 0 ? cards.join(' ') : 'Empty board';
  }

  // JSON serialization
  toJSON(): BoardCards {
    return this.toBoardCards();
  }
}

// Utility functions for working with multiple boards
export class BoardManager {
  private boards: Map<BoardNumber, BoardType>;

  constructor() {
    this.boards = new Map();
    this.boards.set(1, BoardType.createEmpty());
    this.boards.set(2, BoardType.createEmpty());
  }

  getBoard(boardNumber: BoardNumber): BoardType {
    return this.boards.get(boardNumber) || BoardType.createEmpty();
  }

  setBoard(boardNumber: BoardNumber, board: BoardType): void {
    this.boards.set(boardNumber, board.clone());
  }

  clearBoard(boardNumber: BoardNumber): void {
    this.boards.set(boardNumber, BoardType.createEmpty());
  }

  clearAllBoards(): void {
    this.boards.set(1, BoardType.createEmpty());
    this.boards.set(2, BoardType.createEmpty());
  }

  getAllUsedCards(): Set<string> {
    const usedCards = new Set<string>();
    this.boards.forEach(board => {
      board.getAllCards().forEach(card => usedCards.add(card));
    });
    return usedCards;
  }

  randomizeBoard(
    boardNumber: BoardNumber,
    usedCards: Set<string> = new Set(),
    street: Street = 'flop'
  ): void {
    const board = this.getBoard(boardNumber);
    board.randomize(usedCards, street);
    this.setBoard(boardNumber, board);
  }

  randomizeStreet(
    boardNumber: BoardNumber,
    street: Street,
    usedCards: Set<string> = new Set()
  ): void {
    const board = this.getBoard(boardNumber);
    board.randomizeStreet(street, usedCards);
    this.setBoard(boardNumber, board);
  }

  getBoardsArray(): BoardType[] {
    return [this.getBoard(1), this.getBoard(2)];
  }

  toBoardCardsArray(): BoardCards[] {
    return this.getBoardsArray().map(board => board.toBoardCards());
  }
}
