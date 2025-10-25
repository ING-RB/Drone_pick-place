function T = popredo(r)
%POPREDO  Pops last transaction in Redo stack.

%   Author: P. Gahinet  
%   Copyright 1986-2004 The MathWorks, Inc.

% Get last undone transaction
T = r.Redo(end);

% Remove it from Redo stack
r.Redo = r.Redo(1:end-1);

% Add it to Undo stack
r.Undo = [r.Undo ; T];
