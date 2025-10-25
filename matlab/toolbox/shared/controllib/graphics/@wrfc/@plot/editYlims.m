function yLimContainer = editYlims(this,parent,rowIdx,columnIdx)
%EDITYLIMS  Builds group box for Y limit editing.

%   Copyright 1986-2021 The MathWorks, Inc.

arguments
    this
    parent
    rowIdx = 1
    columnIdx = 1
end

% Build standard Y-limit box
yLimContainer = this.AxesGrid.editLimits('Y',parent,rowIdx,columnIdx);
end
