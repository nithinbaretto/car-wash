import {useInfiniteQuery} from '@tanstack/react-query';
import {api, query} from '../api/client';

type ListPage<T, K extends string> = Record<K, T[]> & {hasMore: boolean; nextCursor: string | null};

export function useApiList<T, K extends string>(
  key: string,
  path: string,
  collection: K,
  filters: Record<string, string | undefined> = {},
  refetchInterval?: number,
) {
  const result = useInfiniteQuery({
    queryKey: [key, 'paginated', filters],
    initialPageParam: null as string | null,
    queryFn: ({pageParam, signal}) => api<ListPage<T, K>>(
      `${path}${query({...filters, cursor: pageParam, limit: 25})}`, {signal},
    ),
    getNextPageParam: (lastPage) => lastPage.hasMore ? lastPage.nextCursor ?? undefined : undefined,
    refetchInterval,
  });
  return {
    ...result,
    data: result.data ? {[collection]: result.data.pages.flatMap((page) => page[collection])} as Record<K, T[]> : undefined,
  };
}
