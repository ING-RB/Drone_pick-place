function b = inner2outer(a)
%

%   Copyright 2017-2024 The MathWorks, Inc.

import matlab.lang.internal.move % Avoid unsharing of shared-data copy across function call boundary

aData = a.data;
aWidth = a.varDim.length;
tableVars = false(1,aWidth);
for d = 1:aWidth
    tableVars(d) = istabular(aData{d});
end    

% If there are nested tables, do the inversion work.
if nnz(tableVars)>0
    % Create a table of logicals to track inner and outer vars. This table has
    % one (named) row for each inner var in a, and one var for each outer var in
    % a. So tableNesting{innerVarName,outerVarName} is true if the specified
    % outer var contains the specified inner var.
    w = warning('off', 'MATLAB:table:RowsAddedExistingVars');
    wobj = onCleanup(@() warning(w));
    vars = repmat({false(0,1)},1,aWidth);
    % Dim names are arbitrary and never get out, just don't clash with var names.
    tableNesting = table.init(vars,0,{},aWidth,a.varDim.labels,a.metaDim.labels);
    for ii = find(tableVars)
% Since ii is a numeric value, directly using dot indexing is OK.
        tableNesting{a.(ii).varDim.labels,ii} = true;
    end
    
    % find non-nested variables a(:,~tableVars)
    bNonNested = a(:,~tableVars);
    % a(:,[]) to just get row labels and table metadata.
    bNested = a(:,[]);
    
    % Build up the nested table.
    % Loop over the inner vars in a (outer vars in b). For each inner var
    % in a, loop over the outer vars in a that contain that inner var,
    % building up that table for b.
    for ii = 1:numel(tableNesting.rowDim.labels)
        bOuter = tableNesting.rowDim.labels{ii};
        % Get list of inner var names to go in b corresponding to the outer
        % var in b that we're working on (bOuter).
        bInnerVarNames = tableNesting.varDim.labels(tableNesting{bOuter,:});
        % Set up an empty inner table from the outer variable in a
        % (bInnerVarNames(1) that is the first one that has the inner
        % variable that we're working on now (bOuter).
        % Explicitly call dotReference to always dispatch to subscripting code, even
        % when the variable name matches an internal tabular property/method.
        % tempInner = a.(bInnerVarNames(1))
        tempInner = a.dotReference(bInnerVarNames{1});
        tempInner = tempInner(:,[]);
        for bi = 1:numel(bInnerVarNames)
            bInner = bInnerVarNames{bi};
            % tempInner(:,bInner) = a.bInner(:,bOuter)
            bInnerNoClash = matlab.lang.makeUniqueStrings(bInner,tempInner.metaDim.labels,namelengthmax);
            % Explicitly call dotReference to always dispatch to subscripting code, even
            % when the variable name matches an internal tabular property/method.
            innerTable = a.dotReference(bInner);
            tempInner(:,bInnerNoClash) = innerTable(:,bOuter);
        end
        % clean up per-table metadata
        tempInner = tempInner.setDescription(tempInner.arrayPropsDflts.Description);
        tempInner = tempInner.setUserData(tempInner.arrayPropsDflts.UserData);
        tempInner.arrayProps.TableCustomProperties = struct; % Clear per-table CustomProperties from inner table.
        
        % All inner timetables become tables and lose their row times.
        % Inner tables with row names lose their row names.
        if isa(tempInner,'timetable')
            tempInner = timetable2table(tempInner,'ConvertRowTimes',false);
        else
            tempInner.rowDim = tempInner.rowDim.removeLabels();
        end
        bOuterNoClash = matlab.lang.makeUniqueStrings(bOuter,bNested.metaDim.labels,namelengthmax);
        % Explicitly call dotAssign to always dispatch to subscripting code, even
        % when the variable name matches an internal tabular property/method.
        % bNested.(bOuterNoClash) = tempInner;
        bNested = move(bNested).dotAssign(bOuterNoClash, tempInner);
    end
    dupNames = intersect(bNonNested.varDim.labels,bNested.varDim.labels);
    if ~isempty(dupNames)
        bNested.varDim = bNested.varDim.setLabels(matlab.lang.makeUniqueStrings(bNested.varDim.labels,bNonNested.varDim.labels));
    end
    b = bNonNested.horzcat(bNested);
    
    % Loop over tableNesting rows to figure out where the bNested variables
    % should be located. Find the first true for each inner var (across a
    % row), add 1 for each time multiple new vars need to be moved to the
    % same place.
    prevFind = 0;
    dupShift = 0;
    for jj = 1:tableNesting.rowDim.length
        tableNestingData = [tableNesting.data{:}]; % get logical data
        % New nested table variables are always after the non-nested ones
        % and always get moved to the left, so no need to compensate for
        % the previous moves in the indexing.
        moveFromInd = bNonNested.varDim.length + jj; 
        % Find the first occurrence in the logical array of where the old
        % inner nested variable occurs. Add one each iteration to account
        % for the previous var that was moved (again, always moved left).
        newFind = find(tableNestingData(jj,:),1);
        if prevFind == newFind
            dupShift = dupShift + double(prevFind==newFind);
        end
        prevFind = newFind;
        moveToInd =  newFind + dupShift;
        b = b.movevars(moveFromInd,'Before',moveToInd);
    end
else
    b = a;
end
