export interface Pot {
  potNumber: number; // 1 = main pot, 2+ = side pots
  size: number;
  players: number[]; // playerIds eligible to win this pot
}


