function focus = recomputeAutoTimeFocus(this)
% recomputeAutoTimeFocus sets the TimeFocus to empty, then recomputes and
% returns focus value.

% Copyright 2023 The MathWorks, Inc.
this.TimeFocus = [];
focus = getfocus(this);
end

