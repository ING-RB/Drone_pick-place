function updateShowGroupingVariable(this)
%

%   Copyright 2015-2020 The MathWorks, Inc.

ngl = this.NumGroupLevel;
grpIdx = this.GroupIndex_I;
if ~isempty(this.View.GroupingVariable)
    n = size(grpIdx,1);
    showgv = this.View.ShowGroupingVariable;
    idx_showgv = find(showgv == 1);
    this.ShowGroupingVariableIndex = idx_showgv;
    grpIdx = grpIdx(:,idx_showgv);
    if isempty(grpIdx) % all ShowGroupingVariable elements are 0;
        grpIdx = ones(n,1);
    end
    ngl = ngl(idx_showgv);
    if isempty(ngl)
        ngl = 1;
    end
end
this.GroupIndex_Show = grpIdx;
this.NumGroup_I = ngl;
end
