function updateGroup(this)
%

%   Copyright 2015-2020 The MathWorks, Inc.

tbl = this.View.Data;
n = size(tbl,1);
gvar = this.View.GroupingVariable;
grpbins = this.View.GroupBins;
if ~isempty(gvar)
    g = tbl(:,gvar);
    [grpIdx,gb,glabel,ngl,wrongGrp,wrongBinFlag] = group(g,grpbins);  
   
    % 'undefined group' for data not in any group bin
    ngrpIdx = size(grpIdx,2);
    nangrp = zeros(1,ngrpIdx);
    maxIdx = max(grpIdx);
    dataNoGrpFlag = false;
    for i = 1:ngrpIdx
        idx = (grpIdx(:,i)==0);
        if any(idx)
            dataNoGrpFlag = true;
            nangrp(i) = 1;
            grpIdx(idx,i) = maxIdx(i)+1;
            this.NanGroup(i) = 1;
            ngl(i) = ngl(i)+1;
        end
    end
    if dataNoGrpFlag
        warning(message('Controllib:plotmatrix:DataWithNoGroup'));
    end
    this.NanGroup = nangrp;
    
    this.GroupBins = gb;
    this.GroupLabels_I = glabel; % labels from group bins
    this.WrongGroup = wrongGrp; % groups in the bins but not in the data
    this.WrongBinFlag = wrongBinFlag;   
else % no grouping variable
    grpIdx = ones(n,1);
    ngl = 1;
end
this.GroupIndex_I = grpIdx;
this.NumGroupLevel = ngl; % number of group levels in each grouping variable
                          % used for trellis plot and ShowGroupingVariable
end

function  [grpIdx,gb,glabel,ng,wrongGrp,wrongBinFlag] = group(g,grpbins)
[n,ngv] = size(g);
grpIdx = zeros(n,ngv);
gb = cell(1,ngv);
glabel = cell(1,ngv);
ng = zeros(1,ngv);
wrongGrp = cell(1,ngv);
wrongBinFlag = zeros(1,ngv);
for i = 1:ngv
    if ~iscell(grpbins{i})
        if ngv==1 % char/number
            grpbins={grpbins}; % {'USA','France'}->{{'USA','France'}}
        else %{'USA',{70,76,82}}
            grpbins{i} = grpbins(i); % ->{{'USA'},{70,76,82}}
        end
    end
    gbins_i = grpbins{i}(:);
    gi = g{:,i};
    if ~isa(gi,'double') % categorical
        if isempty(gbins_i) || isscalar(gbins_i) && isempty(gbins_i{:})
            [grpIdx(:,i),glabel{i}] = statslib.internal.grp2idx(gi);
            glabel{i} = glabel{i}'; % row vector
            ng(i) = numel(glabel{i}); % number of group in each grouping variable
        else
            ng(i) = size(gbins_i,1);
            gIdx = zeros(n, 1);
            if ischar(gi)
                gi = categorical(cellstr(gi));
            else %datetime/logical/...
                gi = categorical(gi);
            end
            for j = 1:ng(i)
                gbins_j = gbins_i{j};
                try
                if isa(gbins_j,'double')
                    gbins_j = categorical(gbins_i{j});
                else %char/...
                    gbins_j = categorical(gbins_i(j));
                end
%                 try
                    tf = (gi==gbins_j); %{70,76,[82 83]}, {70,76,{82,83}}
                    if size(tf,2) ~= 1
                        error(message('Controllib:plotmatrix:InvalidGroupBins'));
                    end
                catch
                    error(message('Controllib:plotmatrix:InvalidGroupBins')); %ith
                end
                if all(tf==0)
                    ng(i) = ng(i)-1;
                    wrongGrp{i} = [wrongGrp{i} j];
                else
                    gIdx(tf) = j;
                end
            end
            if ng(i) == 0
                warning(message('Controllib:plotmatrix:NonExistedGroupBins'));
                wrongBinFlag(i) = 1;
%                 error(message('Controllib:plotmatrix:NonExistedGroupBins'));
            end
            if ~isempty(wrongGrp{i})
                gbins_i(wrongGrp{i}) = [];
                for k = 1:numel(wrongGrp{i})
                    idx_k = gIdx>wrongGrp{i}(k);
                    gIdx(idx_k) = gIdx(idx_k)-1;
                    wrongGrp{i}(wrongGrp{i}>wrongGrp{i}(k)) = wrongGrp{i}(wrongGrp{i}>wrongGrp{i}(k))-1;
                end
            end
            glabel{i} = gbins_i';
            grpIdx(:,i) = gIdx; % may contain grpIdx==0, will delete later
        end
        gb{i} = glabel{i};
        if all(cellfun(@isnumeric,glabel{i}))
            glabel{i} = cellfun(@num2str,glabel{i},'UniformOutput',false);
        end
    else % continuous
        if ~isscalar(gbins_i) %1x1 cell that contains a vector or matrix
            error(message('Controllib:plotmatrix:NumericGroupBins'));
        end
        if ~isempty(gbins_i{:})
            gbins_i = gbins_i{:};
            if ~isnumeric(gbins_i) 
                error(message('Controllib:plotmatrix:NumericGroupBins'));
            end
            if isvector(gbins_i)               
                if gbins_i(1)~=-Inf
                    gbins_i = [-Inf;gbins_i(:)];
                end
                if gbins_i(end)~=Inf
                    gbins_i = [gbins_i(:);Inf];
                end
                ng(i) = length(gbins_i)-1;
                grpbin = zeros(ng(i),2);
                grpbin(:,1) = gbins_i(1:end-1);% [-Inf;gbins_i(:)];
                grpbin(:,2) = gbins_i(2:end);% [gbins_i(:);Inf];
                gbins_i = grpbin;
            else %ismatrix
                ng(i) = size(gbins_i,1); 
                if size(gbins_i,2)~=2
                    error(message('Controllib:plotmatrix:NumericGroupBins'));
                end
                gbins_i(1,1) = -Inf;
                gbins_i(end,end) = Inf;
            end
            gn_I = cell(1,ng(i)); %group name
            gIdx = zeros(n, 1);
            for j = 1:ng(i)
                idx_j = (gi <= gbins_i(j,2) & gi > gbins_i(j,1));
                if all(idx_j == 0) % some bins do not exist in the grouping variable.
                    ng(i) = ng(i)-1;
                    wrongGrp{i} = [wrongGrp{i} j];
                else
                    if any(gIdx(idx_j)~=0)
                        error(message('Controllib:plotmatrix:OverlappedGroupBins')); %jth
                    else
                        gIdx(idx_j) = j;
                    end
                end
            end
            if ng(i)==0
                warning(message('Controllib:plotmatrix:NonExistedGroupBins'));
                wrongBinFlag(i) = 1;
            end
            if ~isempty(wrongGrp{i})
                gn_I(wrongGrp{i}) = [];
                gbins_i(wrongGrp{i},:) = [];
                for k = 1:numel(wrongGrp{i})
                    idx_k = gIdx>wrongGrp{i}(k);
                    gIdx(idx_k) = gIdx(idx_k)-1;
                    wrongGrp{i}(wrongGrp{i}>wrongGrp{i}(k)) = wrongGrp{i}(wrongGrp{i}>wrongGrp{i}(k))-1;
                    % after gIdx changed, wrongGrpIdx should change correspondingly
                end
            end
            gbins_i(1,1) = -Inf;
            gbins_i(end,2) = Inf;
            grpIdx(:,i) = gIdx;
            for j = 1:ng(i)
                gn_I{j} = strcat('[',num2str(gbins_i(j,1)),',',num2str(gbins_i(j,2)),']');
            end
            glabel{i} = gn_I;
            gb{i} = gbins_i;
        else
            range_gi = max(gi)-min(gi);
            bin1 = min(gi)+range_gi/3;
            bin2 = max(gi)-range_gi/3;
            if bin1==bin2
                gIdx = ones(n,1);
                gb{i} = [-Inf bin1];
                glabel{1} = {'group'};
                ng = 1;
            else
                gIdx = zeros(n,1);                
                gIdx(gi <= bin1) = 1;
                gIdx(gi > bin2) = 3;
                if any(gIdx == 0)
                    gIdx(gIdx == 0)=2;
                    glabel{i} = {'Low','Medium','High'};
                    gb{i} = [-Inf bin1;bin1 bin2;bin2 Inf];
                    ng(i) = 3;
                else
                    glabel{i} = {'Low','High'};
                    ng(i) = 2;
                    gb0 = min(gi)+range_gi/2;
                    gb{i} = [-Inf gb0;gb0 Inf];
                    gIdx(gi <= gb0) = 1;
                    gIdx(gi > gb0) = 2;
                end                
            end
            grpIdx(:,i) = gIdx;
        end
    end
end
if any(cellfun(@(x)~isempty(x),wrongGrp) & ~wrongBinFlag)
    warning(message('Controllib:plotmatrix:EmptyGroupBins'));
end
end
