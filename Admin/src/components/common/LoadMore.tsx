import {Box, Button} from '@mui/material';

export function LoadMore({hasMore, loading, onClick}: {hasMore: boolean; loading: boolean; onClick: () => void}) {
  if (!hasMore) return null;
  return <Box sx={{display: 'flex', justifyContent: 'center', py: 2}}>
    <Button variant="outlined" onClick={onClick} disabled={loading}>
      {loading ? 'Loading…' : 'Load more'}
    </Button>
  </Box>;
}
