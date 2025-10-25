function undo(t)
% Undoes transaction.

%   Copyright 1986-2004 The MathWorks, Inc.
feval(t.UndoFcn{:});