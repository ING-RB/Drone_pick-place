function s = summary(t,varargin)
%

% Copyright 2012-2025 The MathWorks, Inc.

import matlab.internal.display.lineSpacingCharacter
import matlab.tabular.Continuity

isStatisticsSet = false;
isDataVarsSet = false;
specifiedStats = {};
doCounts = true;
statsIsDefault = true;
doLowDetail = true;
dataVarInd = [];
hasStructOutput = nargout > 0;

if nargin > 1
    dataistabular = true;
    dataislogical = false;
    [isStatisticsSet,specifiedStats,doCounts,doLowDetail,isDataVarsSet,dataVarInd,statsIsDefault] = ...
        matlab.internal.math.parseSummaryNVArgs(varargin,dataistabular,dataislogical,t,hasStructOutput);
end

if isDataVarsSet
    t = t(:,dataVarInd);
end

[stats,statFields,fcnHandles] = matlab.internal.math.createStatsList(t,1,isStatisticsSet,specifiedStats);

descr = t.getProperty('Description',true);
vardescr = t.getProperty('VariableDescriptions',true);
units = t.getProperty('VariableUnits',true);
if hasStructOutput
    nameValidationFlag = 'warn';
else
    nameValidationFlag = 'silent';
end

outputStruct = struct;

% Handle row times if it exists
rowLabelsStruct = t.summarizeRowLabels(stats,statFields,fcnHandles);
if numel(fieldnames(rowLabelsStruct))
    %Combine rowDim name and varnames temporarily to make them valid and jointly unique for the output struct.
    varnames = t.varDim.makeValidName([t.metaDim.labels{1}, t.getProperty('VariableNames',true)],nameValidationFlag);
    varnames = matlab.lang.makeUniqueStrings(varnames,1:t.varDim.length,namelengthmax);
    % varnames{1} is the rowDim name
    outputStruct.(varnames{1}) = rowLabelsStruct;
    % Remove the rowDim name for looping over vars and for printing.
    varnames = varnames(2:end);
else
    varnames = t.varDim.makeValidName(t.getProperty('VariableNames',true),nameValidationFlag);
    varnames = matlab.lang.makeUniqueStrings(varnames,1:t.varDim.length,namelengthmax);
end

continuity = t.getProperty('VariableContinuity',false);

% Handle custom properties
customVarPropNames = fieldnames(t.varDim.customProps);

% Loop through the variables to calculate individual variable summary
for j = 1:t.varDim.length
    var_j = t.data{j};

    % Add size, type to struct for variable summary
    varStruct = struct; % Create new every loop
    varStruct.Size = size(var_j);
    varStruct.Type = class(var_j);
    
    % Add units and var descr if they exist
    varStruct.Description = vardescr{j};
    varStruct.Units = units{j};
    if ~isempty(continuity)
        varStruct.Continuity = continuity(j);
    else
        varStruct.Continuity = [];
    end

    % Add counts if needed
    if doCounts
        if iscategorical(var_j)
            varStruct = categoricalSummary(var_j, varStruct);
        elseif islogical(var_j)
            varStruct = logicalSummary(var_j, varStruct);
        end
    end

    % Add statistics
    % If Statistics is default and the input is logical, only compute the
    % logicalSummary (i.e., True and False) rather than the full list
    % (i.e., NumMissing, Min, Median, Max, Mean, Std). Likewise, if
    % Statistics is default and the input is char, only compute NumMissing.
    if ischar(var_j) && statsIsDefault
        varStruct.NumMissing = sum(ismissing(var_j),1);
    elseif ~(islogical(var_j) && statsIsDefault)
        arrayStruct = matlab.internal.math.datasummary(var_j,stats,statFields,fcnHandles,1);
        varStruct = mergeStructs(varStruct,arrayStruct);
    end
    
    % Store custom properties summary for the given variable
    if ~isempty(customVarPropNames)
        for i = 1:numel(customVarPropNames)
            if ~isempty(t.varDim.customProps.(customVarPropNames{i}))
                varStruct.CustomProperties.(customVarPropNames{i}) = t.varDim.customProps.(customVarPropNames{i})(j); % i is property name index, j is variable index
            else
                varStruct.CustomProperties.(customVarPropNames{i}) = []; % special case for empty, all its variable field should have empty
            end
        end
    end
    
    % Save resulting variable summary struct into output struct
    outputStruct.(varnames{j}) = varStruct;
end

% Display or return
if hasStructOutput
    s = outputStruct;
else
    printSummary(outputStruct,t,varnames,doLowDetail,statFields,inputname(1),descr);
end

%-----------------------------------------------------------------------------
function printSummary(outputStruct,t,varNames,doLowDetail,statLabels,tableName,descr)
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
szT = size(t);

% matlab.internal.display.getDimensionSpecifier returns the small 'x'
% character for size, e.g., 'mxn'
szStr = [sprintf('%d',szT(1)) sprintf([matlab.internal.display.getDimensionSpecifier,'%d'],szT(2:end))];
fprintf('%s %s\n',szStr,class(t));
fprintf(lineSpacingCharacter);

% Display table description
if ~isempty(descr)
    descriptionLabel = getString(message('MATLAB:summary:Description'));
    fprintf('%s: %s\n',descriptionLabel,descr);
    fprintf(lineSpacingCharacter);
end

dimName = t.getProperty('DimensionNames');
varNamesOrig = t.getProperty('VariableNames');
% Print row times information if needed
if isfield(outputStruct, dimName{1})
    rowLabelsStruct = outputStruct.(dimName{1});
    t.printRowLabelsSummary(rowLabelsStruct,doLowDetail);
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
    var = t.data{i};
    varStruct = outputStruct.(varNames{i});
    
    sz = varStruct.Size;
    % Only display size for empty, multi-column, or mutidimensional
    % variables, or a nested table.
    % Store this information in displayVarSize because we will use it again
    % later to determine whether to print the variable in the stats table
    displayVarSize(i) = isempty(var) || numel(sz) > 2 || istabular(var);
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
    if iscellstr(var) %#ok<ISCLSTR>
        typeLabel = getString(message('MATLAB:summary:CellStr'));
    elseif iscategorical(var)
        if isfield(varStruct,'Categories')
            numLabels = numel(varStruct.Categories);
        end
        if isordinal(var)
            typeLabel = getString(message('MATLAB:summary:Ordinal',varStruct.Type));
        else
            typeLabel = varStruct.Type;
        end
    else
        if issparse(var)
            typeLabel = getString(message('MATLAB:summary:Sparse',varStruct.Type));
        else
            typeLabel = varStruct.Type;
        end
    end
    fprintf(['    ' varnameFmt ':%s %s'],varNamesOrig{i},szStr,typeLabel);

    % Print (units, counts, variable description)
    hasUnits = ~isempty(varStruct.Units);
    prefix = ' (';
    suffix = '';
    if hasUnits
        fprintf(' (%s',varStruct.Units);
        prefix = ', ';
        suffix = ')';
    end

    if doLowDetail
        if iscategorical(var) && isfield(varStruct,'Categories') && isscalar(numLabels)
            fprintf(prefix);
            linkText = getString(message('MATLAB:summary:DisplayNumCategories', numLabels));
            if matlab.internal.display.isHot ... % the environment supports hyperlinks
                    && ~isempty(tableName)
                printCategoricalHyperlink(varNamesOrig{i},tableName,numLabels,linkText);
            else
                fprintf(linkText);
            end
            prefix = ', ';
            suffix = ')';
        elseif islogical(var) && isfield(varStruct,'True') && isscalar(varStruct.True)
            % For low detail, only print the count of true values
            numTrue = varStruct.True;
            if issparse(numTrue)
                numTrue = full(numTrue);
            end
            fprintf('%s%u true',prefix,numTrue);
            prefix = ', ';
            suffix = ')';
        end

        if ~isempty(varStruct.Description)
            descrWidth = 64;
            if strlength(varStruct.Description) <= descrWidth
                fprintf('%s%s',prefix,varStruct.Description);
            else
                fprintf('%s%s...',prefix,varStruct.Description(1:descrWidth));
            end
            suffix = ')';
        end
        fprintf('%s\n',suffix);
    else
        fprintf('%s\n',suffix);
        sp8 = '        ';
        
        if isfield(varStruct,'Description') && ~isempty(varStruct.Description)
            fprintf([sp8 'Description:  %s\n'],varStruct.Description);
        end

        if isfield(varStruct,'Continuity') && ~isempty(varStruct.Continuity)
            fprintf([sp8 'Continuity:  %s\n'],varStruct.Continuity);
        end

        if isfield(varStruct,'TimeZone') && ~isempty(varStruct.TimeZone)
            fprintf([sp8 'TimeZone:  %s\n'],varStruct.TimeZone);
        end

        % Print CustomProperties
        customVarPropNames = fieldnames(t.varDim.customProps);
        if ~isempty(customVarPropNames)
            for cidx = 1:numel(customVarPropNames)
                CustomVarProp = varStruct.CustomProperties.(customVarPropNames{cidx});
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
    if ~ismatrix(var)
        continue; 
    end
    
    % Parse struct depending on type
    labels = {};
    doTruncate = false;
    if iscategorical(var)
        if ~doLowDetail && isfield(varStruct,'Categories')
            if isfield(varStruct,'NumMissing')
                labels = [varStruct.Categories; categorical.undefLabel]; %#ok<*AGROW>
                values = [varStruct.Counts; varStruct.NumMissing];
            else
                labels = varStruct.Categories;
                values = varStruct.Counts;
            end

            maxNumLabels = 12;
            if numLabels > maxNumLabels && matlab.internal.display.isHot ...
                    && ~isempty(tableName)
                doTruncate = true;
                labels = labels(1:maxNumLabels);
                values = values(1:maxNumLabels,:); % Ok because we aren't printing N-D
            end
        end
    elseif islogical(var)
        if ~doLowDetail && isfield(varStruct,'True') && any([varStruct.True varStruct.False])
            labels = {'True'; 'False'};
            values = [varStruct.True; varStruct.False];
        end
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
            fprintf('        %s:\n',countsLabel);
            fprintf(c);
            printCategoricalHyperlink(varNamesOrig{i},tableName,numLabels)
        else
            fprintf('        Counts:\n');
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

%-----------------------------------------------------------------------------
function varStruct = categoricalSummary(x,varStruct)
counts = countcats(x,1);
cats = categories(x);

varStruct.Categories = cats;
varStruct.Counts = counts;

%-----------------------------------------------------------------------------
function varStruct = logicalSummary(x,varStruct)
varStruct.True = sum(x,1);
varStruct.False = sum(1-x,1);
     
%-----------------------------------------------------------------------------
function outStruct = mergeStructs(outStruct,tempStruct)
% Copy the fields in arrayStruct into outStruct.
% outStruct already contains Size, Type, and count information (if counts
% are needed)
tempStruct = rmfield(tempStruct,{'Size','Type'});
fdnames = fieldnames(tempStruct);
for fd_i = 1:length(fdnames)
    outStruct.(fdnames{fd_i}) = tempStruct.(fdnames{fd_i});
end

%-----------------------------------------------------------------------
function printCategoricalHyperlink(cvar,T,numCats,linkText)
% Adapted from tabular/display
import matlab.internal.display.lineSpacingCharacter;
% Construct the hyperlink. T is the inputname here, and cvar is the
% variable name as we have to grab the variable from the workspace (not the
% variable given to us)
msg = getString(message('MATLAB:summary:DisplayLinkMissingTable', cvar, T));
% Before trying to display the whole summary, the link will verify a
% table with that name and categorical variable exists.
codeToExecute = "if exist('" + T + "','var') && istabular(" + T + ...
    ") && ismember('" + cvar + "'," + T + ".Properties.VariableNames) && iscategorical(" + ...
    T + ".('" + cvar + "')),displayWholeSummary(" + T + ".('" + cvar + ...
    "')),fprintf(matlab.internal.display.lineSpacingCharacter),else,fprintf('" + msg + "\n');end";
if nargin < 4
    linkText = getString(message('MATLAB:summary:DisplayAllCategoriesLink', numCats));
    fprintf("\t\t\t<a href=""matlab:%s"">%s</a>\n"+lineSpacingCharacter,codeToExecute,linkText);
else
    fprintf("<a href=""matlab:%s"">%s</a>",codeToExecute,linkText);
end

%-----------------------------------------------------------------------
