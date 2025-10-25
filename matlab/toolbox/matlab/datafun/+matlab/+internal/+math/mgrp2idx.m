function [indices,numgroups,namesunique,namescomb,counts] = mgrp2idx(group,...
    numrows,inclnan,inclempty,donamesunique,donamescomb,docounts,inclemptycats)
% MGRP2IDX Convert multiple grouping variables to index vector
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%
%   Outputs:
%       INDICES is a vector of group indices.
%
%       NUMGROUPS is the number of groups.
%
%       NAMESUNIQUE is a cell array containing one column vector per
%       grouping variable. Each of the column vectors contain unique
%       elements.
%
%       NAMESCOMB is a cell array containing one column vector per grouping
%       variable. The column vectors contain one row for each distinct
%       combination of grouping variable values.
%
%       COUNTS is a vector containing the group counts for the data.
%
%   Inputs: 
%       GROUP is a grouping variable (categorical variable, numeric vector,
%       numeric matrix, datetime vector, datetime matrix, duration vector, 
%       duration matrix, string matrix, or cell array of strings) or a cell
%       array of grouping variables. If GROUP is a cell array, all of the 
%       grouping variables that it contains must have the same number of 
%       rows. 
%
%       NUMROWS is used only to create a grouping var (all ones) in the 
%       special case when GROUP is a 1x0 cell array containing no grouping 
%       variables (it should be set to the length of the data variable).  
%       It is not used to check lengths of grouping variables against the 
%       data variable; the caller should do that.
%
%       INCLNAN is a true/false flag about whether to include NaNs present 
%       in the group.
%
%       INCLEMPTY is a true/false flag about whether to include
%       intersections of groups whose count is 0.
%
%       DONAMESUNIQUE, DONAMESCOMB, and DOCOUNTS are true/false flags
%       indicating whether the corresponding output is needed. If the value
%       of a flag is false, then the corresponding output is empty. All of
%       these may be omitted as inputs, with false being the default value
%       for each.
%
%       INCLEMPTYCATS is a true/false flag about whether to include
%       categories from one grouping variable that are not represented in
%       the data. By default, this value matches INCLEMPTY. This flag is
%       distinctly different from INCLEMPTY in that it does not speak to
%       empty intersections of groups, only unrepresented categories in a
%       grouping variable. For example, pivot requires placeholders for
%       empty intersections, but may not want to include unrepresented
%       categories. This flag affects grouping variables of type
%       categorical as well as logical (which is treated as a categorical
%       with two categories).
%
%       Note: DONAMESUNIQUE=true is not supported when INCLEMPTY=false. As
%       needed, caller can use unique on each cell in NAMESCOMB.

%   Copyright 2017-2023 The MathWorks, Inc.

% Compute number of grouping variables
ngrps = size(group,2);

% if no grouping vars, create one group containing all observations
namesunique = {};
namescomb = {};
counts = [];
if ngrps == 0
    indices = ones(numrows,1);
    if ~inclempty && numrows==0
        counts = zeros(0,1);
        numgroups = 0;
    else
        counts = numrows;
        numgroups = 1;
    end
    return;
end

if nargin < 8
    inclemptycats = inclempty;
    if nargin < 7
        docounts = false;
        if nargin < 6
            donamescomb = false;
            if nargin < 5
                donamesunique = false;
            end
        end
    end
end

% Special case a single grouping variable
if ngrps == 1
    % one grouping var, unrepresented cats are the only way to get empty groups
    inclempty = inclemptycats;
    if donamesunique || donamescomb
        [indices,numgroups,namesunique{1}] = matlab.internal.math.grp2idx(group{1,1},inclnan,inclempty);
        if donamescomb
            namescomb = namesunique;
            if ~donamesunique
                namesunique = {};
            end
        end
    else
        [indices,numgroups] = matlab.internal.math.grp2idx(group{1,1},inclnan,inclempty);
    end
    
    % if required compute group count
    if docounts
        grpmat = indices;
        grpmat(isnan(grpmat))=[];
        if isempty(grpmat)
            if ~inclempty
                counts = zeros(0,1);
            else
                counts = zeros(numgroups,1);
            end
        else
            counts = accumarray(grpmat,1,[numgroups,1]);
        end
    end
    return;
end

% preallocate to avoid warnings
namesunique = cell(1,ngrps);
namescomb = cell(1,ngrps);
countgrp = zeros(1,ngrps);

% Compute size of group variable to compare vs other group inputs
es = size(group{1,1});

% If all grouping variables are numeric, then we can call unique once
firstCellType = class(group{1});
allNumeric = all(cellfun(@(x)isnumeric(x) && ~issparse(x) && ~isobject(x) && isequal(class(x),firstCellType),group));
if allNumeric && ~inclempty
    % Special case: donamesunique is not supported
    for j = 1:ngrps
        % If group not vector error
        if ~isvector(group{1,j})
            error(message('MATLAB:findgroups:GroupingVarNotVector'));
        end
        
        % Checking input size is correct (needed in findgroups)
        if any(size(group{1,j}) ~= es)
            error(message('MATLAB:findgroups:InputSizeMismatch'));
        end
        
        % If we have row input move to column for easier processing
        if isrow(group{1,j})
            group{1,j} = group{1,j}(:);
        end
    end
    
    [indices,numgroups,namescomb] = numericGroupsUnique([group{:}],inclnan);
    if docounts
        % Compute group count
        counts = accumarray(indices(~isnan(indices)),1);
    end
    return;
end
% Get integer codes and data/names for each grouping variable
for j=1:ngrps
    % Only call with the output arguments required
    if donamesunique || donamescomb
        [g,countgrp(j),namesunique{1,j}] = matlab.internal.math.grp2idx(group{1,j},inclnan,inclemptycats);
    else
        [g,countgrp(j)] = matlab.internal.math.grp2idx(group{1,j},inclnan,inclemptycats);
    end

    % Checking input size is correct (needed in findgroups)
    if any(size(group{1,j}) ~= es)
        error(message('MATLAB:findgroups:InputSizeMismatch'));
    end

    % If first row have to allocate grpmat
    if j == 1
        numrows = size(g,1);
        grpmat = zeros(numrows,ngrps);
    end

    % Assign output group
    grpmat(:,j) = g;
end

% First remove any NaN categories from grpmat (included missing will have
% number not NaNs)
wasnan = any(isnan(grpmat),2);
grpmat(wasnan,:) = [];

% If including empties need to create all groups possible first
if inclempty
    
    % Compute the total number of groups
    prodgrp = prod(countgrp(1:j));
    numgroups = prodgrp;

    % Create linear groupnumber from grpmat
    grplin = sum((grpmat-1).*(prodgrp./cumprod(countgrp)),2)+1;
    
    if donamescomb
        % Get combinations of group names as needed
        [~,namescomb] = matlab.internal.math.combos(countgrp,namesunique);
    end
    
    % Adding back missing groups that were ignored
    indices = NaN(size(wasnan));
    indices(~wasnan) = grplin;
    
    % If we requested groupcounts compute them
    if docounts
        counts = accumarray(grplin,1,[prodgrp,1]);
    end
% If excluding empties things are simpler
else
    % Group according to each distinct combination of grouping variables, use
    % unique rows to determine combinations
    % Inputs for uniquehelper are (data,sorted,keepFirst,byRows,equalNaNs,includeNaNs)
    [urows,~,uj] = matlab.internal.math.uniquehelper(grpmat,true,true,true,true,false);
    
    % Adding back missing groups that were ignored
    indices = NaN(size(wasnan));
    indices(~wasnan) = uj;

    if isempty(uj)
        numgroups = 0;
    else
        numgroups = max(uj);
    end
    
    % If want groupdata need to use uniquerows and original names from
    % grp2idx to create the output combinations in gdata
    if donamescomb
        for j=1:ngrps
            namescomb{1,j} = namesunique{1,j}(urows(:,j));
        end
    end
    
    % If we want group counts also compute them (Ex: groupsummary)
    if docounts
        % Compute group count
        counts = accumarray(uj,1);
    end
end
% Set output values to empty if user doesn't need them
% (At this point they may be accurate or just pre-allocated cell arrays)
if ~donamesunique
    namesunique = {};
end
if ~donamescomb
    namescomb = {};
end

function [indices,gnum,gnames] = numericGroupsUnique(group, inclnan)
% Inputs for uniquehelper are (data,sorted,keepFirst,byRows,equalNaNs,includeNaNs)
[urows,~,indices] = matlab.internal.math.uniquehelper(group,true,true,true,true,logical(inclnan));
gnames = num2cell(urows,1);
if isempty(indices(~isnan(indices)))
    gnum = 0;
else
    gnum = max(indices);
end