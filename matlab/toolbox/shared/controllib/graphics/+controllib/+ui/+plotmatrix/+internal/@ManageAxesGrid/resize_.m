function resize_(this, nR, nC)
% Pass-through to ctrlguis.AxesGrid

%   Copyright 2015-2020 The MathWorks, Inc.

this.AxesGrid.Size = [nR, nC, 1, 1];

setTickMarks(this);

this.notify('SizeChanged');
end
