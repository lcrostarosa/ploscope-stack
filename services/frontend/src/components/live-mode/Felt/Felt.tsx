import React, {
  Children,
  useEffect,
  useMemo,
  useRef,
  isValidElement,
} from 'react';

import type { LiveGameState } from '../../../types/GameStateTypes';
import './Felt.scss';
import BoardContainer from '../BoardContainer/BoardContainer';

export type FeltProps = {
  gameState: LiveGameState;
  children: React.ReactNode;
  editMode?: boolean;
  onBoardCardClick?: (
    meta:
      | { boardType: 'topFlop' | 'bottomFlop'; flopIndex: number }
      | { boardType: 'topTurn' | 'bottomTurn' | 'topRiver' | 'bottomRiver' }
  ) => void;
};

const Felt: React.FC<FeltProps> = ({ gameState, children, editMode, onBoardCardClick }) => {
  const feltRef = useRef<HTMLDivElement | null>(null);
  const topGroupRef = useRef<HTMLDivElement | null>(null);
  const bottomGroupRef = useRef<HTMLDivElement | null>(null);

  const allChildren = useMemo(() => Children.toArray(children), [children]);

  const { topChildren, bottomChildren, otherChildren } = useMemo(() => {
    const topIndices = new Set([0, 1, 7]);
    const bottomIndices = new Set([3, 4, 5]);

    const top: React.ReactNode[] = [];
    const bottom: React.ReactNode[] = [];
    const other: React.ReactNode[] = [];

    for (const child of allChildren) {
      // Expecting <Seat i={number} ... />
      if (isValidElement(child)) {
        const propsAny = child.props as Record<string, unknown>;
        const index = propsAny?.i;
        if (typeof index === 'number') {
          if (topIndices.has(index)) top.push(child);
          else if (bottomIndices.has(index)) bottom.push(child);
          else other.push(child);
        } else {
          other.push(child);
        }
      } else {
        other.push(child);
      }
    }

    return { topChildren: top, bottomChildren: bottom, otherChildren: other };
  }, [allChildren]);

  useEffect(() => {
    const feltEl = feltRef.current;
    if (!feltEl) return;

    const queryBoardEl = (): HTMLElement | null => {
      // Prefer the inner .board (excludes pot display), fallback to .board-container
      const boardInner = feltEl.querySelector<HTMLElement>('.board');
      if (boardInner) return boardInner;
      return feltEl.querySelector<HTMLElement>('.board-container');
    };

    const getGroupUnionRect = (groupSelector: string): DOMRect | null => {
      const nodes = Array.from(
        feltEl.querySelectorAll<HTMLElement>(groupSelector)
      );
      if (nodes.length === 0) return null;
      let top = Infinity;
      let bottom = -Infinity;
      for (const node of nodes) {
        const r = node.getBoundingClientRect();
        if (!Number.isFinite(r.top) || !Number.isFinite(r.bottom)) continue;
        if (r.top < top) top = r.top;
        if (r.bottom > bottom) bottom = r.bottom;
      }
      if (top === Infinity || bottom === -Infinity) return null;
      // Construct a minimal rect-like object with only top/bottom used
      const fake = {
        top,
        bottom,
        left: 0,
        right: 0,
        width: 0,
        height: Math.max(0, bottom - top),
        x: 0,
        y: top,
        toJSON: () => ({ top, bottom }),
      } as unknown as DOMRect;
      return fake;
    };

    const measureAndSetOffsets = () => {
      const boardEl = queryBoardEl();
      if (!boardEl) return;

      const boardRect = boardEl.getBoundingClientRect();
      const topUnion = getGroupUnionRect('.seats-top .seat');
      const bottomUnion = getGroupUnionRect('.seats-bottom .seat');
      if (!topUnion || !bottomUnion) return;

      // Dynamic margins based on board height (avoid static constants)
      const dynamicMargin = Math.max(0, boardRect.height * 0.06); // ~6% of board height

      // Overlap amounts (positive => overlapping)
      const topOverlap = topUnion.bottom - boardRect.top + dynamicMargin;
      const bottomOverlap = boardRect.bottom - bottomUnion.top + dynamicMargin;

      const topShift = topOverlap > 0 ? -topOverlap : 0;
      const bottomShift = bottomOverlap > 0 ? bottomOverlap : 0;

      feltEl.style.setProperty('--seatsTopTranslate', `${topShift}px`);
      feltEl.style.setProperty('--seatsBottomTranslate', `${bottomShift}px`);
    };

    const ro = new ResizeObserver(() => {
      // Batch in rAF to avoid layout thrash
      requestAnimationFrame(measureAndSetOffsets);
    });

    const boardEl = queryBoardEl();
    if (boardEl) ro.observe(boardEl);
    // Observe seat elements directly since they are absolutely positioned
    const observedNodes: Element[] = [];
    const topSeats = feltEl.querySelectorAll('.seats-top .seat');
    const bottomSeats = feltEl.querySelectorAll('.seats-bottom .seat');
    topSeats.forEach(n => {
      ro.observe(n);
      observedNodes.push(n);
    });
    bottomSeats.forEach(n => {
      ro.observe(n);
      observedNodes.push(n);
    });

    window.addEventListener('resize', measureAndSetOffsets);
    // Initial measure after paint
    const id = requestAnimationFrame(measureAndSetOffsets);

    return () => {
      ro.disconnect();
      window.removeEventListener('resize', measureAndSetOffsets);
      cancelAnimationFrame(id);
    };
  }, [children]);

  return (
    <div className="live-table">
      <div className="felt" ref={feltRef}>
        <div className="felt-branding" aria-hidden>
          <img src="/PLOScope_Logo.svg" alt="" className="felt-logo" />
          <span className="felt-text">PLOScope</span>
        </div>
        <BoardContainer
          gameState={gameState}
          editMode={editMode}
          onBoardCardClick={onBoardCardClick}
        />
        <div className="table-seats">
          <div className="seats-top" ref={topGroupRef}>
            {topChildren}
          </div>
          <div className="seats-bottom" ref={bottomGroupRef}>
            {bottomChildren}
          </div>
          {otherChildren}
        </div>
      </div>
    </div>
  );
};

export default Felt;
