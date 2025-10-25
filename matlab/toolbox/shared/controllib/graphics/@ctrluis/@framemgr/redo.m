function Status = redo(h)
%REDO  Undoes transaction.

%   Author(s): P. Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.

% Get last transaction
LastT = h.EventRecorder.popredo;

% Update status
Status = getString(message('Controllib:gui:strRedoingAction',LastT.Name));
h.newstatus(Status);

% Redo it (will perform required updating)
LastT.redo;

% Update history
h.recordtxt('history',Status);

