import { useState, useEffect } from 'react';
import { fetchTasks } from '../api';

export function useTasks(query, status, page, pageSize) {
  const [tasks, setTasks] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    // Cancel this request if inputs change, so an old slow reply can never overwrite the results of a newer search.
    const controller = new AbortController();

    setLoading(true);
    setError(null); // clear the previous error before trying again

    fetchTasks({ query, status, page, pageSize, signal: controller.signal })
      .then((data) => {
        setTasks(data.items);
        setTotal(data.total);
      })
      .catch((err) => {
        if (err.name === 'AbortError') return; // we cancelled it on purpose
        setTasks([]);
        setTotal(0);
        setError(err.message);
      })
      .finally(() => {
        // Always stop the spinner (before, a failed request left it spinning forever).
        if (!controller.signal.aborted) setLoading(false);
      });

    return () => controller.abort();
  }, [query, status, page, pageSize]);

  return { tasks, total, loading, error };
}
