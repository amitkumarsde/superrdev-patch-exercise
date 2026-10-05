import { useState, useEffect } from 'react';

// Returns the value only after it stops changing for `delay` ms.
// Used so we search once the user pauses typing, not on every key press.
export function useDebouncedValue(value, delay = 300) {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);

  return debounced;
}
