import type { ReactNode } from "react";
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
  return (
    <div role="tablist" className={styles.list}>
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
    </div>
  );
}
