function printTabularSummary(outputStruct,tableInfo,tableProperties,statLabels,doLowDetail,tableName)
% PRINTTABULARSUMMARY Internal helper that prints the summary of tabular
% data.

%   Copyright 2024 The MathWorks, Inc.

% This helper is based on printSummary in
% toolbox/matlab/datatypes/@tabular/summary.m with small modifications.
% The tabular code has access to the tabular input for summary to extract
% information directly from it, we use a struct with data size/type
% extracted during the computation of summary.
% Modifications:
% MOD1: get class from struct instead of input t.
% MOD2: get properties from Properties object.
% MOD3: Call internal helper that implements printRowLabelsSummary for
% timetable (for table is no-op). This is a tabular method that we can't
% reuse.
% MOD4: tableInfo contains extra information on the variable class to print
% (e.g. ordinal categorical instead of categorical)
% MOD5: check info in varStruct, not input t.
% MOD6: Do not display the hot link for categories.

import matlab.internal.display.lineSpacingCharacter

bold = matlab.internal.display.isDesktopInUse;
if bold
    varnameFmt = '<strong>%s</strong>';
else
    varnameFmt = '%s';
end

% Display table name, size, and class
fprintf(lineSpacingCharacter);
if ~isempty(tableName)
    fprintf([varnameFmt ': '],tableName);
end
szT = tableInfo.Size; % MOD1: get size from struct instead of input t

% matlab.internal.display.getDimensionSpecifier returns the small 'x'
% character for size, e.g., 'mxn'
szStr = [sprintf('%d',szT(1)) sprintf([matlab.internal.display.getDimensionSpecifier,'%d'],szT(2:end))];
fprintf('%s %s\n',szStr,tableInfo.Class); % MOD1: get class from struct instead of input t
fprintf(lineSpacingCharacter);

% Display table description
if ~isempty(tableProperties.Description) % MOD2: get properties from Properties object.
    descriptionLabel = getString(message('MATLAB:summary:Description'));
    fprintf('%s: %s\n',descriptionLabel,tableProperties.Description);
    fprintf(lineSpacingCharacter);
end

dimName = tableProperties.DimensionNames; % MOD2: get properties from Properties object.
varNamesOrig = tableProperties.VariableNames; % MOD2: get properties from Properties object.
[varNames, modified] = matlab.lang.makeValidName([dimName(1), varNamesOrig]);
if any(modified)
    varNames = matlab.lang.makeUniqueStrings(varNames);
end
% Update dimName and remove it from varNames.
dimName{1} = varNames{1};
varNames(1) = [];
% Print row times information if needed
if isfield(outputStruct, dimName{1})
    rowLabelsStruct = outputStruct.(dimName{1});
    % MOD3: Call internal helper that implements printRowLabelsSummary for
    % timetable (for table is no-op). This is a tabular method that we
    % can't reuse.
    if tableInfo.Class == "timetable"
        matlab.bigdata.internal.util.printRowLabelsSummary(dimName{1},rowLabelsStruct,doLowDetail);
        % MOD4: Use tableInfo for extra information on the variable class to print.
        % Remove extra information from tableInfo.VarClass that belongs to
        % RowTimes.
        tableInfo.VarClass(1) = [];
    end
    doRowTimes = logical(rowLabelsStruct.Size(1)); % false if empty
else
    doRowTimes = false;
end

% Variables
if ~isempty(varNames)
    fprintf([dimName{2} ':\n']);
    fprintf(lineSpacingCharacter);
end

% Print information about each variable
displayVarSize = false(1,numel(varNames));
colsPerVar = zeros(1,numel(varNames));
for i = 1:numel(varNames)
    varStruct = outputStruct.(varNames{i});

    sz = varStruct.Size;
    % Only display size for empty, multi-column, or mutidimensional
    % variables, or a nested table.
    % Store this information in displayVarSize because we will use it again
    % later to determine whether to print the variable in the stats table
    displayVarSize(i) = prod(sz) == 0 || numel(sz) > 2 || varStruct.Type == "table" || varStruct.Type == "timetable"; % MOD5: check info in varStruct, not input t.
    colsPerVar(i) = sz(2);
    if displayVarSize(i)
        szStr = [' ' sprintf('%d',sz(1)) sprintf([matlab.internal.display.getDimensionSpecifier,'%d'],sz(2:end))];
    elseif sz(2) > 1
        multicolumnLabel = getString(message('MATLAB:summary:Column',sz(2)));
        szStr = [' ' multicolumnLabel];
    else
        szStr = '';
    end

    % Display name, type, units, description for the variable, then remove the
    % fields from the struct since they will not be displayed later.
    % MOD4: Use tableInfo for extra information on the variable class to
    % print.
    if isfield(varStruct,'Categories')
        numLabels = numel(varStruct.Categories);
    end
    % Handle special classes (cellstr, ordinal categorical)
    thisVarClass = tableInfo.VarClass{i};
    if thisVarClass == "cellstr"
        typeLabel = getString(message('MATLAB:summary:CellStr'));
    elseif thisVarClass == "ordinal categorical"
        typeLabel = getString(message('MATLAB:summary:Ordinal',varStruct.Type));
    else
        typeLabel = thisVarClass;
    end
    fprintf(['    ' varnameFmt ':%s %s'],varNamesOrig{i},szStr,typeLabel);

    % Print (units, counts, variable description)
    hasUnits = ~isempty(tableProperties.VariableUnits) && ...
        ~isempty(tableProperties.VariableUnits{i}); % MOD2: get properties from Properties object.
    prefix = ' (';
    suffix = '';
    if hasUnits
        fprintf(' (%s',tableProperties.VariableUnits{i});
        prefix = ', ';
        suffix = ')';
    end

    if doLowDetail
        if isfield(varStruct,'Categories') && isscalar(numLabels)
            fprintf(prefix);
            linkText = getString(message('MATLAB:summary:DisplayNumCategories', numLabels));
            % MOD6: Do not display the hot link for categories.
            fprintf(linkText);
            prefix = ', ';
            suffix = ')';
        elseif isfield(varStruct,'True') && isscalar(varStruct.True)
            % For low detail, only print the count of true values
            fprintf('%s%u true',prefix,varStruct.True);
            prefix = ', ';
            suffix = ')';
        end

        if ~isempty(tableProperties.VariableDescriptions) && ...
                ~isempty(tableProperties.VariableDescriptions{i}) % MOD2: get property from properties object.
            descrWidth = 64;
            if strlength(varStruct.Description) <= descrWidth
                fprintf('%s%s',prefix,tableProperties.VariableDescriptions{i});
            else
                fprintf('%s%s...',prefix,tableProperties.VariableDescriptions{i}(1:descrWidth));
            end
            suffix = ')';
        end
        fprintf('%s\n',suffix);
    else
        fprintf('%s\n',suffix);
        sp8 = '        ';

        if ~isempty(tableProperties.VariableDescriptions) && ...
                ~isempty(tableProperties.VariableDescriptions{i}) % MOD2: get property from properties object.
            fprintf([sp8 'Description:  %s\n'],tableProperties.VariableDescriptions{i});
        end

        if ~isempty(tableProperties.Continuity) && ...
                ~isempty(tableProperties.Continuity{i}) % MOD2: get property from properties object.
            fprintf([sp8 'Continuity:  %s\n'],tableProperties.Continuity{i});
        end

        if isfield(varStruct,'TimeZone') && ~isempty(varStruct.TimeZone)
            fprintf([sp8 'TimeZone:  %s\n'],varStruct.TimeZone);
        end

        % Print CustomProperties
        customVarPropNames = fieldnames(tableProperties.CustomProperties); % MOD2: get properties from Properties object.
        if ~isempty(customVarPropNames)
            for cidx = 1:numel(customVarPropNames)
                CustomVarProp = tableProperties.CustomProperties.(customVarPropNames{cidx});
                CustomVarPropSize = size(CustomVarProp);
                CustomVarPropType = class(CustomVarProp);
                % Print value if it is a scalar known type. Else print size and
                % type information.
                if isscalar(CustomVarProp) && (isdatetime(CustomVarProp) || isduration(CustomVarProp) || ...
                        iscalendarduration(CustomVarProp) || iscategorical(CustomVarProp) || (matlab.internal.datatypes.isText(CustomVarProp)) && ~ismissing(CustomVarProp))
                    fprintf('        %s:  %s\n',customVarPropNames{cidx},char(CustomVarProp));
                elseif isscalar(CustomVarProp) && isnumeric(CustomVarProp)
                    fprintf('        %s:  %s\n',customVarPropNames{cidx},num2str(CustomVarProp));
                elseif isscalar(CustomVarProp) && isstring(CustomVarProp) && ismissing(CustomVarProp)
                    % Missing string needs to be special cased as there is no
                    % good way to print missing strings without hardcoding
                    % them.
                    fprintf('        %s:  %s\n',customVarPropNames{cidx},"<missing>");
                else
                    fprintf('        %s:  [%d%s%d %s]\n',customVarPropNames{cidx},CustomVarPropSize(1),matlab.internal.display.getDimensionSpecifier,CustomVarPropSize(2),CustomVarPropType);
                end
            end
        end
    end

    % Nothing else to print for N-D
    if numel(sz) > 2
        continue;
    end

    % Parse struct depending on type
    labels = {};
    doTruncate = false;
    % MOD5: check info in varStruct, not input t.
    if ~doLowDetail && isfield(varStruct,'Categories')
        if isfield(varStruct,'NumMissing')
            labels = [varStruct.Categories; categorical.undefLabel]; %#ok<*AGROW>
            values = [varStruct.Counts; varStruct.NumMissing];
        else
            labels = varStruct.Categories;
            values = varStruct.Counts;
        end

        maxNumLabels = 12;
        if numLabels > maxNumLabels && matlab.internal.display.isHot
            doTruncate = true;
            labels = labels(1:maxNumLabels);
            values = values(1:maxNumLabels,:); % Ok because we aren't printing N-D
        end
    end
    if ~doLowDetail && isfield(varStruct,'True') && any([varStruct.True varStruct.False])
        labels = {'True'; 'False'};
        values = [varStruct.True; varStruct.False];
    end

    if ~isempty(labels)
        % Create numbered names based on number of columns in the variable
        vn = matlab.internal.datatypes.numberedNames('Column ',1:sz(2));

        % Use tabular disp to pretty print the summary values, including the
        % labels as row names and (possibly) column headers for matrix vars as
        % var names. The labels are all text, the values might be numeric or
        % text.
        vt = array2table(values,'RowNames',labels,'VariableNames',vn); %#ok<NASGU>
        c = evalc('disp(vt,bold,12)');

        % The labels, and perhaps some of the values, are text in a cellstr,
        % they display with enclosing braces and quotes. Remove those.
        c = strrep(c, '''', ' ');
        c = strrep(c, '{', ' ');
        c = strrep(c, '}', ' '); % might be spaces between the quote and the right brace

        % Remove the (one) column header for vars that are column vectors.
        if iscolumn(values)
            lf = newline;
            firstTwoLineFeeds = find(c==lf,2,'first');
            c(1:firstTwoLineFeeds(end)) = [];
        end

        if doTruncate
            countsLabel = getString(message('MATLAB:summary:TruncatedCounts',maxNumLabels));
            fprintf('        %s:',countsLabel);
            fprintf(c);
            % MOD6: Do not display the hot link for categories.
            linkText = getString(message('MATLAB:summary:DisplayAllCategoriesLink', numCats));
            fprintf(linkText);
        else
            fprintf('        Counts:');
            fprintf(c);
        end
    end
end
fprintf(lineSpacingCharacter);

% Do not include empty or N-D variables or tabular variables in the statistics table
if any(displayVarSize)
    varNames = varNames(~displayVarSize);
    colsPerVar = colsPerVar(~displayVarSize);
end

% Print statistics table for applicable variables and row times
if ~isempty(statLabels)
    numStats = numel(statLabels);
    numVars = numel(varNames);
    % Create row labels
    numRows = sum(colsPerVar);
    if numRows == numVars
        expandedVarNames = varNames;
    else
        expandedVarNames = strings(1,numRows);
        k = 1;
        for i = 1:numVars
            if colsPerVar(i) == 1
                expandedVarNames(k) = varNames{i};
            else
                for col = 1:colsPerVar(i)
                    expandedVarNames(k+col-1) = [varNames{i} '(:,' num2str(col) ')'];
                end
            end
            k = k + colsPerVar(i);
        end
    end
    if doRowTimes
        expandedVarNames = [dimName{1} expandedVarNames];
        numRows = numRows + 1;
    end

    % Populate statistics table
    tblSz = [numRows numStats];
    varTypes = repmat("cell",1,numStats);
    statsTbl = table(Size=tblSz,VariableTypes=varTypes,RowNames=expandedVarNames,VariableNames=statLabels);
    deleteStat = false(numRows,numStats);
    row_i = 1;
    if doRowTimes
        for stat_i = 1:numStats
            statname = statLabels{stat_i};
            if isfield(rowLabelsStruct,statname)
                value = rowLabelsStruct.(statname);
                statsTbl{1,stat_i} = {value};
            else
                statsTbl{1,stat_i} = {' '};
                deleteStat(1,stat_i) = true;
            end
        end
        row_i = 2;
    end
    for i = 1:numVars
        varStruct = outputStruct.(varNames{i});
        for stat_i = 1:numStats
            statname = statLabels{stat_i};
            if isfield(varStruct,statname)
                value = varStruct.(statname);
                for col = 1:colsPerVar(i)
                    statsTbl{row_i+col-1,stat_i} = {value(col)};
                end
            else
                for col = 1:colsPerVar(i)
                    statsTbl{row_i+col-1,stat_i} = {' '};
                    deleteStat(row_i+col-1,stat_i) = true;
                end
            end
        end
        row_i = row_i + colsPerVar(i);
    end
    deleteRow = all(deleteStat,2);
    deleteStat = all(deleteStat,1);
    if any(deleteStat)
        statsTbl(:,deleteStat) = [];
    end
    if any(deleteRow)
        statsTbl(deleteRow,:) = [];
    end

    if ~isempty(statsTbl)
        if doRowTimes
            statsText = getString(message('MATLAB:summary:StatsTableVarsRowTimes'));
        else
            statsText = getString(message('MATLAB:summary:StatsTableVars'));
        end
        fprintf('%s:\n',statsText)
        fprintf(lineSpacingCharacter);
        c = evalc('disp(statsTbl,bold)');

        % The labels, and perhaps some of the values, are text in a cellstr,
        % they display with enclosing braces and quotes. Remove those.
        c = strrep(c, '''', ' ');
        c = strrep(c, '{', ' ');
        c = strrep(c, '}', ' '); % might be spaces between the quote and the right brace

        % Remove brackets
        c = strrep(c, '[', ' ');
        c = strrep(c, ']', ' ');

        % Remove the horizontal line under the column header
        lf = newline;
        firstTwoLineFeeds = find(c==lf,2,'first');
        c((firstTwoLineFeeds(1)+1):firstTwoLineFeeds(end)) = [];

        fprintf(c);
    end
end
