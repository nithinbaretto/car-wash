import React from 'react';
import {Box, Skeleton, Grid, Card, CardContent} from '@mui/material';

export const TableSkeleton: React.FC<{rows?: number; cols?: number}> = ({rows = 5, cols = 5}) => {
  return (
    <Box sx={{p: 2}}>
      <Skeleton variant="rounded" height={42} sx={{mb: 2, borderRadius: 2}} />
      {Array.from({length: rows}).map((_, i) => (
        <Box key={i} sx={{display: 'flex', gap: 2, mb: 1.5}}>
          {Array.from({length: cols}).map((_, j) => (
            <Skeleton key={j} variant="rounded" height={36} sx={{flex: 1, borderRadius: 1.5}} />
          ))}
        </Box>
      ))}
    </Box>
  );
};

export const CardSkeleton: React.FC<{count?: number}> = ({count = 6}) => {
  return (
    <Grid container spacing={2.5}>
      {Array.from({length: count}).map((_, i) => (
        <Grid key={i} size={{xs: 12, sm: 6, md: 4}}>
          <Card>
            <CardContent sx={{p: 2.75}}>
              <Box sx={{display: 'flex', justifyContent: 'space-between', mb: 2}}>
                <Skeleton variant="text" width={100} height={20} />
                <Skeleton variant="rounded" width={44} height={44} sx={{borderRadius: 3}} />
              </Box>
              <Skeleton variant="text" width={140} height={40} />
              <Skeleton variant="text" width={180} height={18} sx={{mt: 1}} />
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
};
