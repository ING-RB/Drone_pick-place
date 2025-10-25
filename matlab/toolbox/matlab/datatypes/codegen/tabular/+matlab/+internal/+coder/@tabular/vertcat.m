function t = vertcat(varargin)   %#codegen
%VERTCAT Vertical concatenation for tables.
%   T = VERTCAT(T1, T2, ...) vertically concatenates the tables T1, T2, ... .
%   Row names, when present, must be unique across tables.  VERTCAT fills
%   in default row names for the output when some of the inputs have names
%   and some do not.
%
%   Variable names for all tables must be identical except for order.  VERTCAT
%   concatenates by matching variable names.  VERTCAT assigns values for each
%   property (except for RowNames) in T using the first non-empty value for
%   the corresponding property in the arrays T1, T2, ... .
%
%   See also CAT, HORZCAT.

%   Copyright 2019-2020 The MathWorks, Inc.

nin = nargin;  % number of inputs
haveCell = false;
isIdentityElement = false(1,nin);
is0x0Table1 = false(1,nin);
firstNon0x0Table = 0;
foundFirstNon0x0Table = false;
foundFirstNon0x0Cell = false;
hasRowLabels = false;
firstNonDefaultDimName = 0;
nrowsTotal = 0;   % total number of rows, initialized to 0
isExplicit = true;
non0x0Timetables = 0;
for i = 1:nin
    b = varargin{i};
    is0x0 = ismatrix(b) && coder.internal.isConst(size(b)) && size(b,1) == 0 && size(b,2) == 0;
    % If b is variable sized and we have not found our first non-0x0 table yet,
    % then b would be treated as our representative table. Error if at runtime
    % it turns out to be 0x0.
    coder.internal.errorIf(~coder.internal.isConst(size(b)) && ~foundFirstNon0x0Table ...
        && size(b,1) == 0 && size(b,2) == 0,'MATLAB:table:cat:Varsize0x0');
    nrowsTotal = nrowsTotal + size(b,1);
    % check any input is a cell array
    haveCell = haveCell || iscell(b);
    % check for 0x0 tables
    is0x0Table1(i) = isa(b,'matlab.internal.coder.tabular') && is0x0;
    non0x0Timetables = non0x0Timetables + (isa(b,'matlab.internal.coder.timetable') && ~is0x0);
    % check for "identity element" -- 0x0 numeric
    isIdentityElement(i) = (isnumeric(b) && is0x0); 
    % look for first Non-0x0-empty table
    if ~foundFirstNon0x0Table
        if isa(b,'matlab.internal.coder.tabular')
            if ~is0x0
                firstNon0x0Table = i;
                foundFirstNon0x0Table = true;
            elseif firstNon0x0Table == 0
                % set index to point to a table first, but don't set
                % foundFirstNon0x0Table to true. This is for the case when
                % concatenating empty cells and empty tables only.
                firstNon0x0Table = i;  
            end
        elseif iscell(b) && ~is0x0 && ~foundFirstNon0x0Cell
            % The current input is a non-0x0 cell and we have only seen 0x0
            % table or cell arrays before this, so set the index to the current
            % cell. This might still be updated later if we see a non-0x0 table.
            firstNon0x0Table = i;
            foundFirstNon0x0Cell = true;
        end
    end
    % check whether any input has row names. For tables, the only case when the table does not have
    % rowLabels is when the size of rowDim.labels is constant and it is empty.
     hasRowLabels = hasRowLabels || (isa(b,'matlab.internal.coder.tabular') && b.rowDim.hasLabels);        
end
coder.const(hasRowLabels); % this logical needs to be constant

% throw away identity elements
nNonIdentity = nin - sum(isIdentityElement);
inputsNoIdentity = cell(1, nNonIdentity);
is0x0Table = false(1,nNonIdentity);
counter = 1;
for i = 1:nin
    if ~isIdentityElement(i)
        inputsNoIdentity{counter} = varargin{i};
        is0x0Table(counter) = is0x0Table1(i);
        counter = counter + 1;
    end
end

% update first Non-0x0-empty table index after removing identity elements
firstNon0x0Table = firstNon0x0Table - sum(isIdentityElement(1:firstNon0x0Table-1));
coder.const(firstNon0x0Table);   % this index needs to be constant

% check if first argument is a timetable
haveTime = isa(inputsNoIdentity{1},'matlab.internal.coder.timetable');
tt1 = inputsNoIdentity{1};

% determine number of variables and variable labels from first
% non-0x0-empty input
firstNon0x0Input = inputsNoIdentity{firstNon0x0Table};
if iscell(firstNon0x0Input)
    % If the non-0x0 input is a cell convert it to table first
    varnames = matlab.internal.coder.tabular.private.varNamesDim.dfltLabels(1:size(firstNon0x0Input,2));
    b1 = cell2table(firstNon0x0Input, 'VariableNames', varnames);
else % is already a tabular
    b1 = firstNon0x0Input;
end
t_nvars = b1.varDim.length;
t_varLabels = b1.varDim.labels;

% intialize row labels if needed
if hasRowLabels
    if haveTime
        if isa(b1, 'timetable')
            rowLabels = b1.rowDim.createExtendedRowTimes(nrowsTotal);
            first_rowDim = b1.rowDim;
        else
            rowLabels = tt1.rowDim.createExtendedRowTimes(nrowsTotal);
            first_rowDim = tt1.rowDim;
        end
        isExplicit = isa(first_rowDim,'matlab.internal.coder.tabular.private.explicitRowTimesDim') || (non0x0Timetables > 1);
    else
        rowLabels = coder.nullcopy(cell(nrowsTotal, 1));
    end
end

if haveTime
% Create fill value(NaN/NaT) using appropriate format. This will be used to
% fill row times corresponding to table inputs.
    if isa(first_rowDim.labels,'duration')
        fillValue = duration(0,0,NaN,'Format',first_rowDim.labels.Format);
    else
        [~,fmt,tz] = datetime.toMillis(first_rowDim.labels([]));
        fillValue = datetime.fromMillis(NaN,fmt,tz);
    end
end
% if first input is a timetable including 0x0 timetable, declare output as a timetable
if haveTime
    t = tt1.cloneAsEmpty();
else
    t = b1.cloneAsEmpty(); % preserve the subclass
end

% cell array used to store data of all operands, one row for each operand
b_data = cell(numel(inputsNoIdentity),t_nvars);
t_nrows_processed = 0;  % number of rows already processed

% loop through the operands before the first non-0x0 table 
coder.unroll();
for j = 1:firstNon0x0Table-1
    braw = inputsNoIdentity{j};
    braw_wasCell = iscell(braw);
    coder.internal.assert(isa(braw, 'matlab.internal.coder.tabular') || braw_wasCell, 'MATLAB:table:vertcat:InvalidInput');
    if j == 1  % first iteration only
        % It is necessary this variable is assigned in the first iteration 
        % of a for loop rather than before the loop. If referenced before
        % the loop, Coder gets confused about this variable and fails to
        % assign to a new variable every time the array properties get
        % merged. 
        t_arrayProps0 = t.arrayPropsDflts;
    end
    
    if braw_wasCell
        % braw is a cell array. Convert to table, just use some default variable
        % names, which will be ignored anyways
        varnames = t.varDim.dfltLabels(1:size(braw,2));
        b = cell2table(braw, 'VariableNames', varnames);
    else
        b = braw;
    end
    
    t_arrayProps0 = tabular.mergeArrayProps(t_arrayProps0,b.arrayProps);
    
    % Update the index if this is the first table with non-default dim names
    if firstNonDefaultDimName == 0 && ~isequal(b.metaDim.labels, b.defaultDimNames)
        firstNonDefaultDimName = j;
    end
    
    if ~braw_wasCell
        % empty table or timetable, check for error and continue
        coder.internal.errorIf(isa(b, 'matlab.internal.coder.timetable') && ...
            isa(b1, 'matlab.internal.coder.table') && size(b1,2) > 0, 'MATLAB:table:vertcat:Timetable0x0AndTable');
        continue;
    end
    
    b_nvars = b.varDim.length;
    b_nrows = b.rowDimLength();
    
    % check for size mismatch
    sizeMismatch = b_nvars ~= t_nvars;
    coder.internal.errorIf(sizeMismatch && haveCell, 'MATLAB:table:vertcat:SizeMismatchWithCell');
    coder.internal.errorIf(sizeMismatch && ~haveCell, 'MATLAB:table:vertcat:SizeMismatch'); 
    
    for i = 1:t_nvars
        b_data{j,i} = b.data{i};
    end
    
    % for tables (not timetables), update row labels using default labels
    if isa(t, 'matlab.internal.coder.table') && hasRowLabels
        for i = 1:b_nrows
            rowLabels{t_nrows_processed+i} = t.rowDim.dfltLabels(t_nrows_processed + i,true);
        end
    end
    
    t_nrows_processed = t_nrows_processed + b_nrows;
end

% deal with first non-0x0 table

% check first for the case of timetable inputs following cell array inputs
coder.internal.errorIf(isa(b1,'matlab.internal.coder.timetable') && ~haveTime, ...
    'MATLAB:table:vertcat:CellArrayAndTimetable');

% need to clone the varDim first because if the tables are passed in, they are
% constructed in MATLAB, and MATLAB ignores varsize commands. As a result
% metadata such as variableDescriptions and variableUnits will not be
% variable sized, and we may run into issues when merging the metadata
t_varDim = clone(b1.varDim);

% populate row labels and create rowDim
if hasRowLabels
    if haveTime  % timetable
        if isa(b1, 'timetable')   % only copy rowtimes from timetables
            rowLabels(1:b1.rowDimLength()) = b1.rowDim.labels;
        end
    elseif coder.internal.isConst(size(b1.rowDim.labels)) && isempty(b1.rowDim.labels)  
        % b1 does not have row names, use default names
        for i = 1:b1.rowDimLength()
            rowLabels{t_nrows_processed+i} = t.rowDim.dfltLabels(t_nrows_processed + i,true);
        end
    else   % b1 has row names, copy them
        for i = 1:b1.rowDimLength()
            rowLabels{t_nrows_processed+i} = b1.rowDim.labels{i};
        end
    end
end

t_nrows_processed = t_nrows_processed + b1.rowDimLength(); 

% Update the index if this is the first table with non-default dim names
if firstNonDefaultDimName == 0 && ~isequal(b1.metaDim.labels, b1.defaultDimNames)
    firstNonDefaultDimName = firstNon0x0Table;
end

% merge array properties 
if firstNon0x0Table == 1
    % t_arrayProps0 is not defined because there are no operands before the
    % first non-0x0 table
    t_arrayProps1 = b1.arrayProps;
else
    t_arrayProps1 = tabular.mergeArrayProps(t_arrayProps0,b1.arrayProps);
end

for i = 1:t_nvars
    b_data{firstNon0x0Table,i} = b1.data{i};
end

% loop through the rest of operands
coder.unroll();
for j = firstNon0x0Table+1:length(inputsNoIdentity)
    braw = inputsNoIdentity{j};
    braw_wasCell = iscell(braw);
    coder.internal.assert(isa(braw, 'matlab.internal.coder.tabular') || braw_wasCell, 'MATLAB:table:vertcat:InvalidInput');
    if j == firstNon0x0Table+1  % first iteration only
        % It is necessary this variable is assigned in the first iteration 
        % of a for loop rather than before the loop. If referenced before
        % the loop, Coder gets confused about this variable and fails to
        % assign to a new variable every time the array properties get
        % merged. 
        t_arrayProps = t_arrayProps1;
    end
    
    if braw_wasCell
        % braw is a cell array. Convert to table, just use some default variable
        % names, which will be ignored anyways
        varnames = t.varDim.dfltLabels(1:size(braw,2));
        b = cell2table(braw, 'VariableNames', varnames);
    elseif isa(braw,'matlab.internal.coder.timetable') && ~haveTime
        cellfirst = iscell(inputsNoIdentity{1});
        coder.internal.errorIf(cellfirst, 'MATLAB:table:vertcat:CellArrayAndTimetable');
        coder.internal.errorIf(~cellfirst, 'MATLAB:table:vertcat:TableAndTimetable');
        b = braw;  % dummy b assignment just so Coder understands we are not reusing b across different iterations
    else
        b = braw;
    end
    
    t_arrayProps = tabular.mergeArrayProps(t_arrayProps,b.arrayProps);
    
    % Update the index if this is the first table with non-default dim names
    if firstNonDefaultDimName == 0 && ~isequal(b.metaDim.labels, b.defaultDimNames)
        firstNonDefaultDimName = j;
    end
    
    b_nvars = b.varDim.length;
    b_nrows = b.rowDimLength();
    if b_nvars==0 && b_nrows==0 % special case to mimic built-in behavior
        % empty table, do nothing
        continue;
    end
    
    % It's a non-0x0 input with the right size and type.
    rows_j = t_nrows_processed + (1:b_nrows); % row indices in t that b will go into
    
    % check for size mismatch
    sizeMismatch = b_nvars ~= t_nvars;
    coder.internal.errorIf(sizeMismatch && haveCell, 'MATLAB:table:vertcat:SizeMismatchWithCell');
    coder.internal.errorIf(sizeMismatch && ~haveCell, 'MATLAB:table:vertcat:SizeMismatch');
    
    if ~braw_wasCell
        coder.internal.assert(isequal(t_varLabels,b.varDim.labels), ...
            'MATLAB:table:vertcat:UnequalVarNames');
    end
    
    % populate the data
    for i = 1:t_nvars
        b_data{j,i} = b.data{i};
    end
    
    % include input table properties in output table properties
    t_varDim = t_varDim.mergeProps(b.varDim);
    
    t_nrows_processed = t_nrows_processed + b_nrows;
    
    % populate row labels
    if hasRowLabels
        if haveTime   % timetable output
            if isa(b, 'timetable')  % only copy rowtimes from timetable
                rowLabels(rows_j) = b.rowDim.labels;
            else
                rowLabels(rows_j) = fillValue;
            end
        elseif ~isempty(b.rowDim.labels)   % b has row labels
            for i = 1:numel(rows_j)
                rowLabels{rows_j(i)} = b.rowDim.labels{i};
            end
        else     % b does not have row labels, use defaults
            for i = 1:numel(rows_j)
                rowLabels{rows_j(i)} = t.rowDim.dfltLabels(rows_j(i),true);
            end
        end
    end
end

% this assignment is necessary if the first non-0x0 table is also the last
% operand
if firstNon0x0Table == length(inputsNoIdentity)
    t_arrayProps = t_arrayProps1;
end
        
% concatenate each table variable
t_data = cell(1,coder.const(t_nvars));
for i = 1:t_nvars
    if iscell(b_data{firstNon0x0Table,i})  
        % cell variable gets special treatment because of lack of cell
        % array concatenation in codegen
        varwidth = size(b_data{firstNon0x0Table,i}, 2);
        t_data{i} = coder.nullcopy(cell(t_nrows_processed, varwidth));
        rowcounter = 0;
        for l = 1:size(b_data,1)
            if ~is0x0Table(l)  % do nothing if 0x0 table
                currcell = b_data{l,i};
                coder.internal.assert(iscell(currcell), ...
                    'MATLAB:table:vertcat:VertcatCellAndNonCellCodegen');
                coder.internal.assert(ismatrix(currcell), 'MATLAB:table:vertcat:NdCell');                
                coder.internal.assert(size(currcell,2) == varwidth, ...
                    'MATLAB:table:vertcat:VertcatMethodFailed', t_varLabels{i});
                
                for j = 1:varwidth
                    for k = 1:size(currcell,1)
                        t_data{i}{rowcounter+k,j} = currcell{k,j};
                    end
                end
                rowcounter = rowcounter + size(currcell,1);
            end
        end
    else  % all other variable types other than cell arrays
        for l = 1:size(b_data,1)
            coder.internal.assert(is0x0Table(l) || ~iscell(b_data{l,i}), ...
                'MATLAB:table:vertcat:VertcatCellAndNonCellCodegen');
        end
        t_data{i} = vertcat(b_data{~is0x0Table,i}); % []'s are dropped
        coder.internal.assert(size(t_data{i},1) == t_nrows_processed, ...
            'MATLAB:table:vertcat:VertcatWrongLength', t_varLabels{i});
    end
end
t.data = t_data;


if firstNonDefaultDimName ~= 0
    % Get the metaDim from the frist table with non-default dim names
    t.metaDim = inputsNoIdentity{firstNonDefaultDimName}.metaDim;
elseif haveTime && isa(b1, 'table')
    % If inputs include 0x0 timetables and the first non-0x0 tabular input is a 
    % table, use metaDim from 0x0 timetable 
    t.metaDim = tt1.metaDim;
else
    t.metaDim = b1.metaDim;
end

t.varDim = t_varDim;

if haveTime % timetable output
    % Create the appropriate rowDim from the rowtimes
    if isExplicit
        t_rowDim = matlab.internal.coder.tabular.private.explicitRowTimesDim(...
            nrowsTotal, rowLabels); 
    else
        t_rowDim = first_rowDim.createLike(nrowsTotal);
    end
else % table output
    if hasRowLabels
        t_rowDim = b1.rowDim.createLike(nrowsTotal);
        % Error if row labels are duplicates
        t_rowDim = t_rowDim.setLabels(rowLabels,[],nrowsTotal);
    else 
        t_rowDim = b1.rowDim.createLike(nrowsTotal, {});  % set labels to empty
    end
end
t.rowDim = t_rowDim;
t.arrayProps = t_arrayProps;