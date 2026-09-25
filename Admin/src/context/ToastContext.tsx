import React, {createContext, useContext, useState} from 'react';
import {Snackbar, Alert, AlertColor, Slide, SlideProps} from '@mui/material';

interface ToastContextType {
  showToast: (message: string, severity?: AlertColor) => void;
  showSuccess: (message: string) => void;
  showError: (message: string) => void;
  showWarning: (message: string) => void;
  showInfo: (message: string) => void;
}

const ToastContext = createContext<ToastContextType>({
  showToast: () => {},
  showSuccess: () => {},
  showError: () => {},
  showWarning: () => {},
  showInfo: () => {},
});

export const useToast = () => useContext(ToastContext);

function SlideTransition(props: SlideProps) {
  return <Slide {...props} direction="left" />;
}

export const ToastProvider: React.FC<{children: React.ReactNode}> = ({children}) => {
  const [open, setOpen] = useState(false);
  const [message, setMessage] = useState('');
  const [severity, setSeverity] = useState<AlertColor>('info');

  const showToast = (msg: string, sev: AlertColor = 'info') => {
    setMessage(msg);
    setSeverity(sev);
    setOpen(true);
  };

  const showSuccess = (msg: string) => showToast(msg, 'success');
  const showError = (msg: string) => showToast(msg, 'error');
  const showWarning = (msg: string) => showToast(msg, 'warning');
  const showInfo = (msg: string) => showToast(msg, 'info');

  const handleClose = (_?: React.SyntheticEvent | Event, reason?: string) => {
    if (reason === 'clickaway') return;
    setOpen(false);
  };

  return (
    <ToastContext.Provider value={{showToast, showSuccess, showError, showWarning, showInfo}}>
      {children}
      <Snackbar
        open={open}
        autoHideDuration={4000}
        onClose={handleClose}
        anchorOrigin={{vertical: 'bottom', horizontal: 'right'}}
        TransitionComponent={SlideTransition}
      >
        <Alert
          onClose={handleClose}
          severity={severity}
          variant="filled"
          sx={{
            width: '100%',
            fontWeight: 600,
            borderRadius: 2.5,
            boxShadow: '0 10px 30px -5px rgba(0,0,0,0.3)',
          }}
        >
          {message}
        </Alert>
      </Snackbar>
    </ToastContext.Provider>
  );
};
