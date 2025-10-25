function [lkey,rkey] = selectJoinKeys(leftT,rightT)
% selectJoinKeys Helper function for Join Tables Live Task
%
%   [lkey, rkey] = selectJoinKeys(leftTable, rightTable) compares the table
%   variables in leftTable with the table variables in rightTable and
%   returns the best key variable pair to merge the two tables on. lkey is
%   the name of the best key variable in leftTable, rkey is the name of the
%   best key variable in rightTable. lkey or rkey may be empty if no
%   suitable match is found.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2021 The MathWorks, Inc.

% Only calculate scores for variables that are sortable vectors
varsToRemove = varfun(@(x) ~isvector(x) || ~isSortable(x),leftT,"OutputFormat","uniform");
T1 = removevars(leftT,varsToRemove);
varsToRemove = varfun(@(x)~isvector(x) || ~isSortable(x),rightT,"OutputFormat","uniform");
T2 = removevars(rightT,varsToRemove);
if isempty(T1) || isempty(T2)
    % No pairs left to check
    lkey = [];
    rkey = [];
    return
end

score = -inf(width(T1),width(T2));
totalNumRows = height(T1) + height(T2);
isStrType = @(x) iscellstr(x) || isstring(x);
issortedLeft = varfun(@issorted,T1,"OutputFormat","uniform");
issortedRight = varfun(@issorted,T2,"OutputFormat","uniform");
uniquifiedRightVars = cell(width(T2),1);
numUniqueR = zeros(width(T2),1);
for leftIndex = 1:width(T1)
    leftVar = unique(T1.(leftIndex));
    numL = numel(leftVar);
    isNumVar = isnumeric(leftVar) || islogical(leftVar) || isduration(leftVar);
    % column value type: value of 1 if both strings or datetime,
    % value of 2 if both numerical, otherwise 3
    cvt = 3;
    if isdatetime(leftVar) || iscategorical(leftVar) || isStrType(leftVar)
        cvt = 1;
    elseif isNumVar
        cvt = 2;
    end
    for rightIndex = 1:width(T2)
        if leftIndex == 1
            % only uniquify once
            rightVar = unique(T2.(rightIndex));
            uniquifiedRightVars{rightIndex} = rightVar;
            numR = numel(rightVar);
            numUniqueR(rightIndex) = numR;
        else
            rightVar = uniquifiedRightVars{rightIndex};
            numR = numUniqueR(rightIndex);
        end
        % Only consider pairs where classes match
        % Or cellstr with string is ok
        % Or single with double is ok, so long as the double isn't sparse
        % Non-matching int classes will fail in ismember
        if isequal(class(leftVar),class(rightVar)) || (isStrType(leftVar) && isStrType(rightVar)) || ...
                (isfloat(leftVar) && isfloat(rightVar) && (issparse(leftVar) == issparse(rightVar)))
            srt = issortedLeft(leftIndex) && issortedRight(rightIndex);
            % value range overlap: intersection of ranges over union of ranges
            vro = 0;
            if isNumVar
                % calculate vro (both vars have been sorted with unique)
                [minMin,maxMin] = bounds([leftVar(1),rightVar(1)]);
                [minMax,maxMax] = bounds([leftVar(end),rightVar(end)]);
                vro = max((minMax - maxMin)/(maxMax-minMin),0);
            end
            countIntersect = nnz(ismember(leftVar,rightVar));
            countUnion = numL + numR - countIntersect;
            js = countIntersect/countUnion; % Jaccard similarity
            jcL = countIntersect/numL; % Jaccard containment
            jcR = countIntersect/numR; % Jaccard containment
            % value overlap: jaccard-similarity and jaccard-containment in both directions
            vo = mean([js jcL jcR]); % average of jaccard measurements

            % Ratio of distinct elements over total number of table rows
            dvr = countUnion/totalNumRows;

            % The following values come from intern research using
            % https://www.microsoft.com/en-us/research/uploads/prod/2020/04/auto-suggest.pdf
            % as a starting point and tuning using machine learning
            score(leftIndex,rightIndex) = (0.35 * vro) - (0.11 * dvr) + (0.05 * vo)/(0.01 * cvt) + (0.01 * srt);
        end
    end
end
[~,ind] = max(score,[],'all');
[lkey,rkey] = ind2sub(size(score),ind);
lkey = T1.Properties.VariableNames{lkey};
rkey = T2.Properties.VariableNames{rkey};
end

function TF = isSortable(var)
% only datatypes supported by SORT (as per doc)
TF = isnumeric(var) || islogical(var) || ischar(var) || isstring(var) || ...
    iscellstr(var) ||iscategorical(var) || isdatetime(var) || isduration(var);
end