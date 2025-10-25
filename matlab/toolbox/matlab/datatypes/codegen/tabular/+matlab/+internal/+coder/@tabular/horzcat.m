function t = horzcat(varargin)  %#codegen
%HORZCAT Horizontal concatenation for tables.
%   T = HORZCAT(T1, T2, ...) horizontally concatenates the tables T1, T2,
%   ... .  All inputs must have unique variable names.
%
%   Row names for all tables that have them must be identical except for order.
%   HORZCAT concatenates by matching row names when present, or by position for
%   tables that do not have row names.  HORZCAT assigns values for the
%   Description and UserData properties in T using the first non-empty value
%   for the corresponding property in the arrays T1, T2, ... .
%
%   See also CAT, VERTCAT, JOIN.

%   Copyright 2019-2020 The MathWorks, Inc.

nin = nargin;  % number of inputs
haveCell = false;
isIdentityElement = false(1,nin);
firstNon0x0Table = 0;
foundFirstNon0x0Table = false;
firstRowLabels = 0;
foundFirstRowLabels = false;
foundFirstNon0x0Cell = false;
firstNonDefaultDimName = 0;
nvarsTotal = 0; % number of table variables, initialized to 0
for i = 1:nin
    b = varargin{i};
    nvarsTotal = nvarsTotal + size(b,2); % add to number of variables
    % check any input is a cell array
    haveCell = haveCell || iscell(b);
    is0x0 = ismatrix(b) && coder.internal.isConst(size(b)) && size(b,1) == 0 && size(b,2) == 0;
    % If b is variable sized and we have not found our first non-0x0 table yet,
    % then b would be treated as our representative table. Error if at runtime
    % it turns out to be 0x0.
    coder.internal.errorIf(~coder.internal.isConst(size(b)) && ~foundFirstNon0x0Table ...
        && size(b,1) == 0 && size(b,2) == 0,'MATLAB:table:cat:Varsize0x0');
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
    % look for first table with row names
    if ~foundFirstRowLabels && ~is0x0 && (isa(b,'matlab.internal.coder.tabular') ...
            && b.rowDim.hasLabels)
        firstRowLabels = i;
        foundFirstRowLabels = true;
    end
end

% throw away identity elements
nNonIdentity = nin - sum(isIdentityElement);
inputsNoIdentity = cell(1, nNonIdentity);
counter = 1;
for i = 1:nin
    if ~isIdentityElement(i)
        inputsNoIdentity{counter} = varargin{i};
        counter = counter + 1;
    end
end

% update first Non-0x0-empty table index after removing identity elements
firstNon0x0Table = firstNon0x0Table - sum(isIdentityElement(1:firstNon0x0Table-1));
coder.const(firstNon0x0Table);  % this index needs to be constant

% check if first argument is a timetable
haveTime = isa(inputsNoIdentity{1},'matlab.internal.coder.timetable');

% update index of first table with row names after removing identity elements
if foundFirstRowLabels
    firstRowLabels = firstRowLabels - sum(isIdentityElement(1:firstRowLabels-1));
end
coder.const(firstRowLabels);  % this index needs to be constant

% initialize table data
t_data = coder.nullcopy(cell(1,nvarsTotal));

% first non-0x0-empty table determines number of rows in output, and
% metadim
firstNon0x0Input = inputsNoIdentity{firstNon0x0Table};
if iscell(firstNon0x0Input)
    % If the non-0x0 input is a cell convert it to table first
    varnames = matlab.internal.coder.tabular.private.varNamesDim.dfltLabels(1:size(firstNon0x0Input,2));
    b1 = cell2table(firstNon0x0Input, 'VariableNames', varnames);
else % is already a tabular
    b1 = firstNon0x0Input;
end
% if first input is a timetable including 0x0 timetable, declare output as a timetable
if haveTime
    t = inputsNoIdentity{1}.cloneAsEmpty();
else
    t = b1.cloneAsEmpty(); % preserve the subclass
end
varLabels = coder.nullcopy(cell(1, nvarsTotal));
t_nrows = b1.rowDimLength();
t_nvars_processed = 0;  % number of variables already processed

% loop through the operands before the first non-0x0 table
coder.unroll();
for j = 1:firstNon0x0Table-1
    braw = inputsNoIdentity{j};
    braw_wasCell = iscell(braw);
    coder.internal.assert(isa(braw, 'matlab.internal.coder.tabular') || braw_wasCell, 'MATLAB:table:horzcat:InvalidInput');
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
            isa(b1, 'matlab.internal.coder.table') && size(b1,1) > 0, 'MATLAB:table:horzcat:Timetable0x0AndTable');
        continue;
    end
                    
    b_nrows = b.rowDimLength();
    b_nvars = b.varDim.length;
    
    % check for size mismatch
    sizeMismatch = b_nrows ~= t_nrows;
    coder.internal.errorIf(sizeMismatch && haveCell, 'MATLAB:table:horzcat:SizeMismatchWithCell');
    coder.internal.errorIf(sizeMismatch && ~haveCell, 'MATLAB:table:horzcat:SizeMismatch');  
  
    % It's a non-0x0 input with the right size and type. Append it to
    % the right edge of t.
    for i = 1:b_nvars
        idx = t_nvars_processed+i;
        t_data{idx} = b.data{i};
        % generate default labels
        varLabels{idx} = t.varDim.dfltLabels(idx,true);
    end

    t_nvars_processed = t_nvars_processed + b_nvars;
end

% deal with first non-0x0 table

% check first for the case of timetable inputs following cell array inputs
coder.internal.errorIf(isa(b1,'matlab.internal.coder.timetable') && ~haveTime, ...
    'MATLAB:table:horzcat:CellArrayAndTimetable');

b1_nvars = b1.varDim.length;
for i=1:b1_nvars
    t_data{t_nvars_processed+i} = b1.data{i};
    varLabels{t_nvars_processed+i} = b1.varDim.labels{i};
end

t_nvars_processed = t_nvars_processed + b1_nvars;    

% Update the index if this is the first table with non-default dim names
if firstNonDefaultDimName == 0 && ~isequal(b1.metaDim.labels, b1.defaultDimNames)
    firstNonDefaultDimName = firstNon0x0Table;
end

t_varDim = b1.varDim.createLike(nvarsTotal); % empty labels
% include input table properties in output table properties
t_varDim = t_varDim.moveProps(b1.varDim,1:b1.varDim.length,1:b1_nvars);

if foundFirstRowLabels
    % first input with row names determine the output row names
    t_rowDim = inputsNoIdentity{firstRowLabels}.rowDim;
elseif haveTime  % 0x0 timetables, possibly followed by tables
    % use rowDim of first 0x0 timetable
    t_rowDim = inputsNoIdentity{1}.rowDim;
else
    % tables without row names, just use rowDim of first non empty table
    t_rowDim = b1.rowDim;
end

% merge array properties
if firstNon0x0Table == 1
    % t_arrayProps0 is not defined because there are no operands before the
    % first non-0x0 table
    t_arrayProps1 = b1.arrayProps;
else
    t_arrayProps1 = tabular.mergeArrayProps(t_arrayProps0,b1.arrayProps);
end
     
     
% loop through the rest of operands
t_rowDimLabels = t_rowDim.labels;
coder.unroll();
for j = firstNon0x0Table+1:length(inputsNoIdentity)
    braw = inputsNoIdentity{j};
    braw_wasCell = iscell(braw);
    coder.internal.assert(isa(braw, 'matlab.internal.coder.tabular') || braw_wasCell, 'MATLAB:table:horzcat:InvalidInput');
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
        coder.internal.errorIf(cellfirst, 'MATLAB:table:horzcat:CellArrayAndTimetable');
        coder.internal.errorIf(~cellfirst, 'MATLAB:table:horzcat:TableAndTimetable');
        b = braw;  % dummy b assignment just so Coder understands we are not reusing b across different iterations
    else  % table
        b = braw;
    end
    
    t_arrayProps = tabular.mergeArrayProps(t_arrayProps,b.arrayProps);
    
    % Update the index if this is the first table with non-default dim names
    if firstNonDefaultDimName == 0 && ~isequal(b.metaDim.labels, b.defaultDimNames)
        firstNonDefaultDimName = j;
    end
    
    b_nrows = b.rowDimLength();
    b_nvars = b.varDim.length;
    if b_nvars==0 && b_nrows==0 % special case to mimic built-in behavior
        % empty table, do nothing
        continue;
    end
    
    vars_j = t_nvars_processed+(1:b_nvars); % var indices in t that b will go into
    
    % check for size mismatch
    sizeMismatch = b_nrows ~= t_nrows;
    coder.internal.errorIf(sizeMismatch && haveCell, 'MATLAB:table:horzcat:SizeMismatchWithCell');
    coder.internal.errorIf(sizeMismatch && ~haveCell, 'MATLAB:table:horzcat:SizeMismatch');  
  
    % It's a non-0x0 input with the right size and type. Append it to
    % the right edge of t.
    b_rowDim = b.rowDim;
    b_rowDimLabels = b_rowDim.labels;
    
    % check row names match other input tables
    if ~isempty(b_rowDimLabels)
        if haveTime
            coder.internal.assert(isequal(t_rowDimLabels, b_rowDimLabels), ...
                'MATLAB:table:horzcat:UnequalRowTimes');
        else
            coder.internal.assert(isequal(t_rowDimLabels, b_rowDimLabels), ...
                'MATLAB:table:horzcat:UnequalRowNames');
        end
    end
    
    for i = 1:b_nvars
        t_data{t_nvars_processed+i} = b.data{i};
    end

    t_nvars_processed = t_nvars_processed + b_nvars;
    
    % If it was originally a cell array, there are no variable labels or other
    % properties to worry about.
    if ~braw_wasCell  % table or timetable     
        % If it was originally a table or a timetable, get its var labels and
        % per-var properties.
        for i = 1:b_nvars
            varLabels{vars_j(i)} = b.varDim.labels{i};
        end
        t_varDim = t_varDim.moveProps(b.varDim,1:b.varDim.length,vars_j);
    else    % cell
        % for cell array, generate default labels
        for i = 1:b_nvars
            varLabels{vars_j(i)} = t.varDim.dfltLabels(vars_j(i),true);
        end
    end
end

% this assignment is necessary if the first non-0x0 table is also the last
% operand
if firstNon0x0Table == length(inputsNoIdentity)
    t_arrayProps = t_arrayProps1;
end

t.data = t_data;

if firstNonDefaultDimName ~= 0
    % Get the metaDim from the frist table with non-default dim names
    t.metaDim = inputsNoIdentity{firstNonDefaultDimName}.metaDim;
elseif haveTime && isa(b1, 'table')
    % If inputs include 0x0 timetables and the first non-0x0 tabular input is a 
    % table, use metaDim from 0x0 timetable 
    t.metaDim = inputsNoIdentity{1}.metaDim;
else
    t.metaDim = b1.metaDim;
end
% Error if var labels are duplicates
t.varDim = t_varDim.setLabels(varLabels,[],nvarsTotal);

% Detect conflicts between the combined var names of the result and the dim
% names of the leading time/table. 
% Commenting out until dimension names can be changed in codegen.
%t.metaDim = t_metaDim.checkAgainstVarLabels(t.varDim.labels);

t.rowDim = t_rowDim;
t.arrayProps = t_arrayProps;
