function redo(t)
% Redoes transaction.

%   Copyright 1986-2004 The MathWorks, Inc.
feval(t.RedoFcn{:});