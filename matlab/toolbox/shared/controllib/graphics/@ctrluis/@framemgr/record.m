function record(h,T)
%RECORD  Records transaction.

%   Author: P. Gahinet  
%   Copyright 1986-2004 The MathWorks, Inc.

% Commit transaction
T.commit;

% Push onto Undo stack
h.EventRecorder.pushundo(T);
