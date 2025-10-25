function Status = undo(h)
%UNDO  Undoes transaction.

%   Author(s): P. Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.

% RE: Coded for transactions of class ctrluis/transaction 

% Get last transaction
LastT = h.EventRecorder.popundo;

% Update status
Status = getString(message('Controllib:gui:strUndoingAction',LastT.Name));
h.newstatus(Status);

% Undo it (will perform required updating)
LastT.undo;

% Update history
h.recordtxt('history',Status);

