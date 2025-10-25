function writeTable(inputTable,filename,args)
%writetable Write a table to an xml file.

% Copyright 2020-2024 The MathWorks, Inc.

    import matlab.internal.datatypes.matricize

    % Configure the warning state.
    warningCleanup = matlab.io.xml.internal.write.suppressMultipleWarnings();

    % Parse and validate input arguments. Arguments come in as chars, converted
    % by writetable.m.
    nvPairs = parseNameValuePairs(args{:});

    % Move table variables that will be written out as attributes to the front
    % (libxml2 requires attributes of row element to be written out first)
    rearrangedTable = rearrangeTable(inputTable, nvPairs.AttributeSuffix);

    % Extract & matricize variables (convert char to cellstr) and get variable names
    data = cell(1, width(rearrangedTable));
    for ii = 1 : width(rearrangedTable)
        % error if one of the elements is a table
        if isa(rearrangedTable.(ii),'tabular')
            error(message('MATLAB:io:xml:writetable:NestedTable'));
        end
        data{ii} = matricize(rearrangedTable.(ii),true);
    end

    writeParams = struct();
    writeParams.locale = nvPairs.DateLocale;

    % Get variable traits
    varTraits = variableTraits(data);

    % Create distinct variable names for variables with multiple column
    % data
    [allVarNames, writeAttribute] = matlab.io.xml.internal.write.processVariableNames(data, ...
                                                      rearrangedTable.Properties.VariableNames, varTraits, nvPairs.AttributeSuffix);
    varNamesArray = string(allVarNames);
    
    % Namespace prefix declarations are written for variable names,
    % TableNodeName, RowNodeName, and the row dimension name, if
    % WriteVariableNames is true.
    namespacePrefixes = matlab.io.xml.internal.write.getNamespacePrefixes(varNamesArray, nvPairs, inputTable.Properties.DimensionNames{1});

    prefixesWithDeclarations = matlab.io.xml.internal.write.addPrefixDeclarations(namespacePrefixes);
    
    if isempty(data)
        stringData = string.empty();
    else
        % Flatten array data and then convert to string array
        flatData = stringify(data, writeParams, varTraits);
        stringData = string(flatData);
        
        % Add row name node name to varNamesArray and row names to stringData
        if nvPairs.WriteRowNames
            [varNamesArray, stringData, writeAttribute] = writeRowNames(inputTable, ...
                varNamesArray, stringData, writeAttribute);
        end
    end

    % Call builtin to write xml file
    if nvPairs.Streaming
        matlab.io.xml.internal.write.builtin.writetableStreaming(filename, ...
                                                          varNamesArray, stringData, nvPairs, writeAttribute, prefixesWithDeclarations);
    else
        matlab.io.xml.internal.write.builtin.writetableTree(filename, ...
                                                          varNamesArray, stringData, nvPairs, writeAttribute);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rearrangedTable = rearrangeTable(inputTable, AttributeSuffix)
    rearrangedTable = inputTable;
    if ~ismissing(AttributeSuffix)
        attrIdx = endsWith(inputTable.Properties.VariableNames, AttributeSuffix);
        rearrangedTable = movevars(inputTable, attrIdx, 'Before', 1);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function results = parseNameValuePairs(varargin)
    import matlab.io.xml.internal.write.validateNodeName;

    parser = inputParser;
    parser.FunctionName = "writetable";
    parser.StructExpand = false;

    parser.addParameter("TableNodeName", 'table')
    parser.addParameter("RowNodeName", 'row');
    parser.addParameter("AttributeSuffix", 'Attribute');
    parser.addParameter("WriteRowNames", false);

    % Undocumented name-value pairs
    parser.addParameter("Encoding", 'UTF-8');
    parser.addParameter("ToIndent", true);
    parser.addParameter("IndentText", '    ');
    parser.addParameter("Streaming", true);
    parser.addParameter("DateLocale", matlab.internal.datetime.getDefaults('locale'));

    parser.parse(varargin{:});
    results = parser.Results;

    % Validate that TableNodeName, RowNodeName, and AttributeSuffix
    % follow XML specifications
    validateNodeName(results.TableNodeName, "TableNodeName");
    validateNodeName(results.RowNodeName, "RowNodeName");
    results.AttributeSuffix = validateAttributeSuffix(results.AttributeSuffix);

    validateWriteRowNames(results.WriteRowNames);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function validateWriteRowNames(writeRowNames)
    matlab.internal.datatypes.validateLogical(writeRowNames, "WriteRowNames");
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function attributeSuffix = validateAttributeSuffix(attributeSuffix)
%

% Copyright 2020 The MathWorks, Inc.
    validateattributes(attributeSuffix, ["string", "char"], "scalartext",...
                       "writetable", "AttributeSuffix");

    if isempty(attributeSuffix)
        attributeSuffix = string(missing);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [varNamesArray, stringData, writeAttribute] = writeRowNames(T, ...
                                                      varNamesArray, stringData, writeAttribute)
    if ~isempty(T.Properties.RowNames)
        
        % The first dimension name of the table is used as the default row
        % name node name because it must be distinct from the Variable Names
        rowNameNodeName = string(T.Properties.DimensionNames(1));

        % Add the row name node name
        varNamesArray = [rowNameNodeName, varNamesArray];

        % Add the row names to data
        stringData = [string(T.Properties.RowNames), stringData];

        % Add an entry to writeAttribute for the row names
        writeAttribute = [true, writeAttribute];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outData = stringify(inData, writeParams, varTraits)
    nRows = size(inData{1},1);

    % number of output columns will increase if variables have multiple columns
    outColNum = sum([varTraits.nVarFields{:}]);
    outData = cell(nRows, outColNum);
    outCnt = 1;
    
    for ii = 1:numel(inData)
        
        nCols = varTraits.nVarFields{ii};
        if isempty(inData{ii})
           outData(:, outCnt:(outCnt + nCols - 1)) = {''};
        elseif varTraits.isSparse(ii)
            fullData = full(inData{ii});
            outData(:, outCnt:(outCnt + nCols - 1)) = num2cell(fullData);
        elseif varTraits.isNumeric(ii)
            outData(:, outCnt:(outCnt + nCols - 1)) = num2cell(inData{ii});
        elseif varTraits.isCharStrings(ii)
            outData(:, outCnt:(outCnt + nCols - 1)) = inData{ii};
        elseif varTraits.isCategorical(ii)
            outData(:, outCnt:(outCnt + nCols - 1)) = cellstr(string(inData{ii}));
        elseif varTraits.isTime(ii)
            outData(:, outCnt:(outCnt + nCols - 1)) = cellstr(string(inData{ii},[],writeParams.locale));
        elseif varTraits.isNonStringCell(ii)
            for i = 1:size(inData{ii}, 2)
                nCellCols = varTraits.nVarFields{ii}(i);
                outData(:, outCnt:(outCnt + nCellCols - 1)) = stringifycell(inData{ii}(:, i), varTraits.nVarFields{ii}(i), writeParams);
                outCnt = outCnt + nCellCols;
            end
        elseif varTraits.isStringType(ii)
            outData(:, outCnt:(outCnt + nCols - 1)) = cellstr(inData{ii});
        end
        outCnt = outCnt + nCols;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outData = resolveCell(inData, writeParams, varTraits)
% RESOLVECELL formats and converts content of a cell.
    outData = cell(size(inData));

    for ii = 1:numel(inData)
        if ~iscell(inData{ii}) && isempty(inData{ii})
           outData{ii} = {''};
        elseif varTraits.isEmptyCell(ii)
            error(message('MATLAB:io:xml:writetable:EmptyNestedCell'));
        elseif varTraits.isSparse(ii)
            fullData = full(inData{ii});
            outData{ii} = num2cell(fullData);
        elseif varTraits.isNumeric(ii)
            outData{ii} = cellstr(string(inData{ii}));
        elseif varTraits.isCharStrings(ii)
            if iscell(inData)
                error(message('MATLAB:io:xml:writetable:NestedCell'));
            end
            outData{ii} = inData(ii);
        elseif varTraits.isCategorical(ii)
            outData{ii} = cellstr(inData{ii});
        elseif varTraits.isTime(ii)
            outData{ii} = cellstr(inData{ii},[],writeParams.locale);
        elseif varTraits.isStringType(ii)
            strchunk = inData{ii};
            % replace all missing values with empty chars
            missingStrings = ismissing(strchunk);
            strchunk(missingStrings) = "";
            outData{ii} = cellstr(strchunk);
        elseif varTraits.isNonStringCell(ii)
            error(message('MATLAB:io:xml:writetable:NestedCell'));
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outCell = stringifycell(cellVar, nFields, writeParams)
% STRINGFYCELL formats and converts content of each row of a cell array
% into separate variables.

    import matlab.internal.datatypes.matricize

    % The STRINGIFY helper function assumes row cell vector. Stretch cell
    % variable out to a 1-by-numel(cellVar) cell to facilitate the call
    [nCellRows, nCellCols] = size(cellVar); % cache the shape for reconstruction at the end
    cellVar = cellVar(:)';

    % Matricize elements in cellVar (convert char to cellstr) as subsequent
    % processing assumes 2D content in the cells.
    cellVar = cellfun(@(var)matricize(var,true),cellVar,'UniformOutput',false);

    % variable traits of contents in this cell
    varTraits = variableTraits(cellVar);

    % convert contents into cell array of strings
    cellVar = resolveCell(cellVar, writeParams, varTraits);

    % Content of each cell is linearly indexed out as delimited fields in
    % each table row. Since each table row must have the same number of
    % fields, rows with fewer fields need to be pad up with empty fields.
    % The correct number of fields for each cell column is passed in
    % (nFieldsCells). Compute the number of empty fields to pad with respect to
    % number of elements in each cell.
    nFieldsCells = cellfun(@(x)max(numel(x),1),cellVar); % number of fields (at least one) in each cell
    nPadFields = max(repelem(nFields,nCellRows)-nFieldsCells, 0);

    % reshape back to the original number of rows
    cellVar = reshape(cellVar, nCellRows, nCellCols);

    % preallocate output cell array
    outCell = cell(nCellRows, max(nFieldsCells));

    % fill output cell array and add pad cells
    for i = 1:numel(cellVar)
        padCells = cellstr(strings(nPadFields(i), 1));
        currCell = [cellVar{i}(:); padCells];
        outCell(i, :) = currCell;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varTraits = variableTraits(cellVector)
% VARIABLETRAITS returns a varTraits struct with type traits of contents in
% cellVector and number of delimited fields needed to write out content of
% each variable in nVarFields.

    function m = numCellVarFields(c)
    % Number of delimited fields or columns needed to write out the
    % contents of a cell (excluding contents in nested cells)
        if isnumeric(c) || islogical(c) || iscategorical(c) || isdatetime(c) || isduration(c) || iscalendarduration(c) || isstring(c)
            m = max(numel(c),1); % always write out at least one empty field
        else % unsupported types
            m = 1;
        end
    end

    % Table variable traits
    nVars = numel(cellVector);
    varTraits.nVarFields = cell(1, nVars);
    for i = 1:nVars
        x = cellVector{i};

        % Table variable type info
        varTraits.isEmptyCell(i)       = isempty(x) && iscell(x);
        varTraits.isNumeric(i)         = islogical(x) || isnumeric(x);
        varTraits.isCharStrings(i)     = ischar(x) || matlab.internal.datatypes.isCharStrings(x);
        varTraits.isCategorical(i)     = iscategorical(x);
        varTraits.isTime(i)            = isdatetime(x) || isduration(x) || iscalendarduration(x);
        varTraits.isNonStringCell(i)   = iscell(x) && ~varTraits.isCharStrings(i);
        varTraits.isSparse(i)          = issparse(x);
        varTraits.isComplex(i)         = isnumeric(x) && ~isreal(x);
        varTraits.isStringType(i)      = isstring(x);

        % Number of fields to write from each variable. For regular non-cell
        % variables, number of fields is a scalar; for cell-variable with
        % multiple columns, number of fields is a row-vector with element
        % mapping to each column of the cell.
        if varTraits.isNonStringCell(i)
            % Multiple rows in each cell element are converted to delimited
            % fields. Number of fields for each column of a cell variable thus
            % equals to the maximum number of rows in that column.
            varTraits.nVarFields{i} = max(cellfun(@numCellVarFields,x), [], 1);
        else
            varTraits.nVarFields{i} = max(size(x, 2), 1); % always write out at least one empty field
        end

        varTraits.isUnsupportedType(i) = ~(varTraits.isNumeric(i) || ...
                                           varTraits.isCharStrings(i) || varTraits.isCategorical(i) || ...
                                           varTraits.isTime(i) || varTraits.isNonStringCell(i) || ...
                                           varTraits.isStringType(i));
        if varTraits.isUnsupportedType(i)
            error(message('MATLAB:io:xml:writetable:UnsupportedType'));
        end
    end
end
