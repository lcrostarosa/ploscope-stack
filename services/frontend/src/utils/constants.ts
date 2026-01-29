// Looser types to avoid strict blowups across the app while we migrate

// Emoji suits for display only
export const suits: string[] = ['♠', '♥', '♦', '♣'];
// Text suits for internal processing, state storage, and API calls
export const shortSuits: string[] = ['s', 'h', 'd', 'c'];
export const ranks: string[] = [
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  'T',
  'J',
  'Q',
  'K',
  'A',
];

const suitClassMap = new Map([
  ['♥', 'hearts'],
  ['♦', 'diamonds'],
  ['♠', 'spades'],
  ['♣', 'clubs'],
]);

export const getSuitClass = (suit: string): string => {
  return suitClassMap.get(suit) || '';
};

const suitMap = new Map([
  ['♥', 'h'],
  ['♦', 'd'],
  ['♠', 's'],
  ['♣', 'c'],
]);

export const getSuitShort = (suit: string): string => {
  return suitMap.get(suit) || '';
};

const shortSuitMap = new Map([
  ['h', '♥'],
  ['d', '♦'],
  ['s', '♠'],
  ['c', '♣'],
]);

export const getSuitEmoji = (shortSuit: string): string => {
  return shortSuitMap.get(shortSuit) || '';
};

export const convertCardToShortFormat = (card: string): string => {
  if (!card) return '';

  // If card is already in short format (e.g., 'As', 'Kh'), return as-is
  if (card.length === 2 && 'hdcs'.includes(card[1])) {
    return card;
  }

  // If card is in emoji format (e.g., 'A♠', 'K♥'), convert to short format
  if (card.length === 2 && '♥♦♠♣'.includes(card[1])) {
    const rank = card[0];
    const suit = card[1];
    return `${rank}${getSuitShort(suit)}`;
  }

  // For longer cards, assume first char is rank and last char is suit
  if (card.length > 2) {
    const rank = card[0];
    const suit = card[card.length - 1];

    // If suit is already short format
    if ('hdcs'.includes(suit)) {
      return `${rank}${suit}`;
    }

    // If suit is emoji format
    if ('♥♦♠♣'.includes(suit)) {
      return `${rank}${getSuitShort(suit)}`;
    }
  }

  // Return as-is if we can't determine the format
  return card || '';
};

export const convertCardToEmojiFormat = (card: string): string => {
  if (!card) return '';

  // If card is already in emoji format (e.g., 'A♠', 'K♥'), return as-is
  if (card.length === 2 && '♥♦♠♣'.includes(card[1])) {
    return card;
  }

  // If card is in short format (e.g., 'As', 'Kh'), convert to emoji format
  if (card.length === 2 && 'hdcs'.includes(card[1])) {
    const rank = card[0];
    const suit = card[1];
    return `${rank}${getSuitEmoji(suit)}`;
  }

  // For longer cards, assume first char is rank and last char is suit
  if (card.length > 2) {
    const rank = card[0];
    const suit = card[card.length - 1];

    // If suit is already emoji format
    if ('♥♦♠♣'.includes(suit)) {
      return `${rank}${suit}`;
    }

    // If suit is short format
    if ('hdcs'.includes(suit)) {
      return `${rank}${getSuitEmoji(suit)}`;
    }
  }

  // Return as-is if we can't determine the format
  return card || '';
};

/**
 * Convert cards from emoji format to short format for backend API calls
 * @param {string|Array} cards - Single card string or array of card strings
 * @returns {string|Array} - Converted card(s) in short format
 */
export const convertCardsForBackend = (
  cards: string | string[]
): string | string[] => {
  if (!cards) return cards;

  if (Array.isArray(cards)) {
    return cards
      .map(card => convertCardToShortFormat(card))
      .filter(Boolean) as string[];
  }

  return convertCardToShortFormat(cards);
};

/**
 * Convert cards from short format to emoji format for frontend display
 * @param {string|Array} cards - Single card string or array of card strings
 * @returns {string|Array} - Converted card(s) in emoji format
 */
export const convertCardsForFrontend = (
  cards: string | string[]
): string | string[] => {
  if (!cards) return cards;

  if (Array.isArray(cards)) {
    return cards
      .map(card => convertCardToEmojiFormat(card))
      .filter(Boolean) as string[];
  }

  return convertCardToEmojiFormat(cards);
};

export const generateDeck = (): string[] => {
  // Use shortSuits for internal processing (text format: As, Kh, etc.)
  return shortSuits.flatMap(suit => ranks.map(rank => `${rank}${suit}`));
};

export const shuffle = <T>(deck: T[]): T[] => {
  const newDeck = [...deck];
  for (let i = newDeck.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [newDeck[i], newDeck[j]] = [newDeck[j], newDeck[i]];
  }
  return newDeck;
};

export const generateRandomCards = (
  numCards: number,
  excludeCards: Set<string> = new Set()
): string[] => {
  // Use shortSuits for internal processing (text format: As, Kh, etc.)
  const allCards = shortSuits.flatMap(suit =>
    ranks.map(rank => `${rank}${suit}`)
  );
  const availableCards = allCards.filter(card => !excludeCards.has(card));

  if (availableCards.length < numCards) {
    throw new Error('Not enough available cards');
  }

  const shuffled = [...availableCards];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }

  return shuffled.slice(0, numCards);
};
