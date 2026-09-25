import React, {useState} from 'react';
import {Box} from '@mui/material';
import {useTheme} from '@mui/material/styles';
import {Sidebar} from './Sidebar';
import {Header} from './Header';

interface ShellProps {
  children: React.ReactNode;
}

const DRAWER_WIDTH = 260;

export const Shell: React.FC<ShellProps> = ({children}) => {
  const [mobileOpen, setMobileOpen] = useState(false);
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  return (
    <Box sx={{display: 'flex', minHeight: '100vh', backgroundColor: 'background.default'}}>
      {/* Sidebar */}
      <Sidebar
        mobileOpen={mobileOpen}
        onMobileClose={() => setMobileOpen(false)}
        drawerWidth={DRAWER_WIDTH}
      />

      {/* Main Content Area */}
      <Box
        sx={{
          flexGrow: 1,
          display: 'flex',
          flexDirection: 'column',
          minWidth: 0,
        }}
      >
        <Header onMenuClick={handleDrawerToggle} drawerWidth={DRAWER_WIDTH} />

        <Box
          component="main"
          sx={{
            flexGrow: 1,
            p: {xs: 2, sm: 3, md: 4},
            maxWidth: 1600,
            width: '100%',
            mx: 'auto',
          }}
        >
          {children}
        </Box>
      </Box>
    </Box>
  );
};
