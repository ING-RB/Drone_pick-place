function reset(~, Curves)
% Reset line data in given curves. 

% Copyright 2013 The MathWorks, Inc.

for ct = 1:numel(Curves)
   set(Curves(ct), 'Xdata', [], 'Ydata', [], 'Zdata', [])
end
