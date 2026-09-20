import { useLayoutEffect, useRef, useState, type ReactNode } from "react";
import styles from "./Tabs.module.css";

export interface TabItem<Id extends string> {
  id: Id;
  label: string;
  icon: ReactNode;
}

interface TabsProps<Id extends string> {
  items: readonly TabItem<Id>[];
  selected: Id;
  onSelect: (id: Id) => void;
}

/** Labelled tabs, every one with a word next to its icon. */
export function Tabs<Id extends string>({ items, selected, onSelect }: TabsProps<Id>) {
  const listRef = useRef<HTMLDivElement>(null);
  const [indicator, setIndicator] = useState<{ left: number; width: number } | null>(null);

  // Measure the selected tab so the underline can slide to it. Layout
  // effect, so the first paint already has it in place rather than
  // animating in from nowhere.
  useLayoutEffect(() => {
    const list = listRef.current;
    const tab = list?.querySelector<HTMLElement>('[role="tab"][aria-selected="true"]');
    if (!list || !tab) {
      return;
    }
    setIndicator({ left: tab.offsetLeft, width: tab.offsetWidth });
  }, [selected, items]);

  return (
    <div ref={listRef} role="tablist" className={styles.list}>
      {items.map((item) => (
        <button
          key={item.id}
          type="button"
          role="tab"
          aria-selected={item.id === selected}
          className={styles.tab}
          onClick={() => onSelect(item.id)}
        >
          {item.icon}
          <span>{item.label}</span>
        </button>
      ))}
      {indicator && <div className={styles.indicator} style={{ left: indicator.left, width: indicator.width }} />}
    </div>
  );
}
