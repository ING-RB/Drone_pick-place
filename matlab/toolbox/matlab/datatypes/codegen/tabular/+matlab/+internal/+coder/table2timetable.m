function tt = table2timetable(t,varargin)  %#codegen
%TABLE2TIMETABLE Convert table to timetable.

%   Copyright 2019-2022 The MathWorks, Inc.
coder.internal.prefer_const(varargin);
coder.extrinsic('getString', 'message', 'matlab.internal.i18n.locale');

coder.internal.assert(isa(t,'table'), 'MATLAB:table2timetable:NonTable');

tprops = t.Properties;
tvarnames = tprops.VariableNames;
getRowtimesFromTable = false;

if nargin == 1
    % Take the time vector as the first datetime/duration variable in the table.
    % If the table is n-by-p, the timetable will be n-by-(p-1).
    rowtimesIndex = 0;
    coder.unroll();
    for i = 1:width(t)
        v = t.(i);
        if isa(v,'datetime') || isa(v,'duration')
            rowtimesIndex = i;
            break;
        end
    end
    coder.internal.assert(rowtimesIndex > 0, 'MATLAB:table2timetable:NoTimeVarFound');    
    rowsDimname = tvarnames{rowtimesIndex};
    getRowtimesFromTable = true;
    pstruct.RowTimes = uint32(1);
else
    % Take the time vector as the RowTimes input, or as the specified variable in the table.
    % If the table is n-by-p, the timetable will be n-by-p, or n-by-(p-1), respectively.
    pnames = {'VariableNames' 'RowTimes'  'SampleRate'  'TimeStep'  'StartTime'};
    poptions = struct( ...
        'CaseSensitivity',false, ...
        'PartialMatching','unique', ...
        'StructExpand',false);
    pstruct = coder.internal.parseParameterInputs(pnames,poptions,varargin{:});

    rowtimesIn = coder.internal.getParameterValue(pstruct.RowTimes,[],varargin{:});
    sampleRate = coder.internal.getParameterValue(pstruct.SampleRate,[],varargin{:});
    timeStep = coder.internal.getParameterValue(pstruct.TimeStep,[],varargin{:});
    startTime = coder.internal.getParameterValue(pstruct.StartTime,seconds(0),varargin{:});
    useSampleRate = (pstruct.SampleRate ~= 0);
    
    [rowtimesDefined,startTime,timeStep,sampleRate] ...
        = matlab.internal.coder.tabular.validateTimeVectorParams ((pstruct.RowTimes ~= 0),...
        startTime,(pstruct.StartTime ~= 0), timeStep, (pstruct.TimeStep ~= 0), sampleRate, useSampleRate);

    coder.internal.errorIf(pstruct.VariableNames ~= 0, 'MATLAB:table2timetable:VariableNamesNotAccepted');
    % error if neither RowTimes, TimeStep, nor SampleRate was specified
    coder.internal.assert(rowtimesDefined, 'MATLAB:timetable:NoTimeVector');

    if pstruct.RowTimes
        % If the RowTime parameter is supplied, figure out if it's an
        % explicit vector, or a reference to a table variable.
        if isa(rowtimesIn,'datetime') || isa(rowtimesIn,'duration')
            % The input table defines the size of the output timetable. The time
            % vector must have the same length as the table has rows, even if
            % the table has no vars.
            coder.internal.assert(numel(rowtimesIn) == height(t), ...
                'MATLAB:table2timetable:IncorrectNumberOfRowTimes');
            
            % use default rowDim name
            rowsDimname = coder.const(getString(message('MATLAB:timetable:uistrings:DfltRowDimName'),...
                        matlab.internal.i18n.locale('en_US'))); 
            
            % Make sure the default timetable row dim name doesn't conflict
            % with any of the input table's var names
            %rowsDimname = matlab.lang.makeUniqueStrings(rowsDimname,varnames,namelengthmax);
        elseif matlab.internal.coder.datatypes.isScalarText(rowtimesIn)
            % The row times are specified as a variable in the table.
            rowsDimname = convertStringsToChars(rowtimesIn);     
            rowtimesIndex = 0;
            coder.unroll();
            for i = 1:width(t)
                if strcmp(rowtimesIn, tvarnames{i})
                    rowtimesIndex = i;
                    break;
                end
            end
            coder.internal.assert(coder.internal.isConst(rowtimesIndex), ...
                'MATLAB:table:NonconstantVarIndex');
            coder.internal.assert(rowtimesIndex > 0, ...
                'MATLAB:table:UnrecognizedVarName',rowsDimname);
            getRowtimesFromTable = true;
        else
            coder.internal.assert(matlab.internal.datatypes.isScalarInt(rowtimesIn,1), ...
                'MATLAB:table2timetable:InvalidRowTimes');
            rowtimesIndex = rowtimesIn;
            coder.internal.assert(coder.internal.isConst(rowtimesIndex), ...
                'MATLAB:table:NonconstantVarIndex');
            coder.internal.assert(rowtimesIndex <= width(t), ...
                'MATLAB:table:VarIndexOutOfRange');           
            rowsDimname = tvarnames{rowtimesIndex};
            getRowtimesFromTable = true;
        end
    else
        % use default rowDim name
        rowsDimname = coder.const(getString(message('MATLAB:timetable:uistrings:DfltRowDimName'),...
            matlab.internal.i18n.locale('en_US')));
    end
end

% If the row times were specified as a variable in the table, take that var out
% of the table. Copy the per-variable properties also.
tvars = getVars(t,false);
if getRowtimesFromTable
    rowtimes = tvars{rowtimesIndex};
    nvars = numel(tvars)-1;
    vars1 = cell(1,nvars);
    varnames1 = cell(1,nvars);
    vardesc1 = cell(1,nvars);
    varunits1 = cell(1,nvars);
    if nvars > 0
        varcont1 = repmat(matlab.internal.coder.tabular.Continuity.unset,1,nvars);
    else
        varcont1 = [];
    end
    for i = 1:nvars
        if i >= rowtimesIndex
            vars1{i} = tvars{i+1};
            varnames1{i} = tvarnames{i+1};
            vardesc1{i} = tprops.VariableDescriptions{i+1};
            varunits1{i} = tprops.VariableUnits{i+1};
            varcont1(i) = tprops.VariableContinuity(i+1);
        else
            vars1{i} = tvars{i};
            varnames1{i} = tvarnames{i};
            vardesc1{i} = tprops.VariableDescriptions{i};
            varunits1{i} = tprops.VariableUnits{i};
            varcont1(i) = tprops.VariableContinuity(i);
        end
    end    
else
    rowtimes = rowtimesIn;
    vars1 = tvars;
    varnames1 = tvarnames;
    vardesc1 = tprops.VariableDescriptions;
    varunits1 = tprops.VariableUnits;
    varcont1 = tprops.VariableContinuity;
end

% Include the table's row names, if any
rownames = tprops.RowNames;
if isvector(rownames)
    % Create a variable from the row names, named according to the input's row
    % dim name, at the front of the table. 
    nvars = numel(vars1)+1;
    vars = cell(1,nvars);
    varnames = cell(1,nvars);
    vardesc = cell(1,nvars);
    varunits = cell(1,nvars);
    varcont = repmat(matlab.internal.coder.tabular.Continuity.unset,1,nvars);
    vars{1} = rownames;
    varnames{1} = tprops.DimensionNames{1};
    vardesc{1} = '';
    varunits{1} = '';
    for i = 2:nvars
        vars{i} = vars1{i-1};
        varnames{i} = varnames1{i-1};
        vardesc{i} = vardesc1{i-1};
        varunits{i} = varunits1{i-1};
        varcont(i) = varcont1(i-1);
    end
else
    vars = vars1;
    varnames = varnames1;
    vardesc = vardesc1;
    varunits = varunits1;
    varcont = varcont1;
end


nvars = length(vars);
% Need to look at the original table for number of rows, in case there are no vars
% from which to get this info.
nrows = height(t);

% Use the specified table var name (or the default) for the row dim name, and
% take the var dim name from the timetable.
dimnames = {rowsDimname,tprops.DimensionNames{2}};

if pstruct.RowTimes
    tt = timetable.init(vars,nrows,rowtimes,nvars,varnames,dimnames);
else % pstruct.TimeStep || pstruct.SampleRate
    tt = timetable.initRegular(vars,nrows,startTime,timeStep,sampleRate,nvars,varnames,dimnames);
end

% Copy over the per-array and per-var metadata, but not the the row or dim names.
ttprops = tt.Properties;
ttprops.VariableDescriptions = vardesc;
ttprops.VariableUnits = varunits;
ttprops.VariableContinuity = varcont;
ttprops.Description = tprops.Description;
% Cannot copy UserData, because of a limitation UserData cannot be assigned
% after table/timetable construction
%ttprops.UserData = tprops.UserData;
tt.Properties = ttprops;