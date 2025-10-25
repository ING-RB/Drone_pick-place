function updateGroupLabelsAndShowGroups(this)
%

%   Copyright 2015-2020 The MathWorks, Inc.

if ~isempty(this.View.GroupingVariable)
    glabel = this.View.GroupLabels;
    showgrp = this.View.ShowGroups;
    gl = this.GroupLabels_I;
    ngv = this.View.NumGroupingVariable;
    ngl = this.NumGroupLevel;
    wrongGrp = this.WrongGroup;
    nangrp = this.NanGroup;
    gname = cell(1,ngv);   
    
    for i = 1:ngv
        if this.View.ChangedGroupIdx(i)
            if ~isempty(glabel{i})
                if iscell(glabel{i}) %{{'a','b','c'},{'a','b','c'}}
                    gname{i} = glabel{i};
                else
                    if ngv==1 % char/number,{'a','b','c'}, {1970,1976,1982}
                        gname{i} = glabel; % {'USA','France'}->{{'USA','France'}}
                    else %{'USA',{70,76,82}}
                        gname{i} = glabel(i); % ->{{'USA'},{70,76,82}}
                    end
                end
                nglabel = numel(gname{i});
                if ~isempty(glabel{i}) && (nglabel+nangrp(i))~=(ngl(i)+numel(wrongGrp{i}))
                    error(message('Controllib:plotmatrix:WrongNumElement','GroupLabels'));
                end
                gname{i}(wrongGrp{i}) = [];
                gl{i} = gname{i};
            end
            if isempty(showgrp{i})
                showgrp{i} = true(1,ngl(i)-nangrp(i));
            else
                if (size(showgrp{i},2)+nangrp(i)) ~= (ngl(i)+numel(wrongGrp{i}))
                    error(message('Controllib:plotmatrix:WrongNumElement','ShowGroups'));
                end
                showgrp{i}(wrongGrp{i}) = [];
            end
            if nangrp(i)
                gl{i}(end+1) = {'undefined'};
                showgrp{i}(end+1) = 1;
            end
        else
            gl{i} = glabel{i};
        end
    end
    this.View.GroupLabels = gl;
    this.View.ShowGroups = showgrp;
end
end
