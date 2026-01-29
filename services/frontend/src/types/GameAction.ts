export type GameStreet = 'preflop' | 'flop' | 'turn' | 'river';

export type ActionName = 'fold' | 'check' | 'call' | 'bet' | 'raise' | 'allin';

export interface ActionRecord {
  playerId: number;
  action: ActionName;
  amount: number;
  street: GameStreet;
}


