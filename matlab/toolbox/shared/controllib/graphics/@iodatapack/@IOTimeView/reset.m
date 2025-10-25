function reset(this)
% Reset curves to empty.

%  Copyright 2013 The MathWorks, Inc.

CG = this.Curves;
for ct = 1:numel(CG)   
   set(CG(ct), 'Xdata',[], 'YData', []);
end
