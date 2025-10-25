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
yLimContainer.LimitsLabelText{1} = sprintf('(%s)',getString(message('Controllib:plots:strMagnitude')));
yLimContainer.LimitsLabelText{2} = sprintf('(%s)',getString(message('Controllib:plots:strPhase')));
