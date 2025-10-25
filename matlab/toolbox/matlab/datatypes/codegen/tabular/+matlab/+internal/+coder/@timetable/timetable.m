classdef (Sealed) timetable < matlab.internal.coder.tabular  %#codegen
%TIMETABLE Timetable.

%   Copyright 2019-2024 The MathWorks, Inc.
        
    properties(Constant, GetAccess='public')
        propertyNames = matlab.internal.coder.timetable.getPropertyNamesList;
        defaultDimNames = dfltTimetableDimNames();
        RowDimNameNondefaultExceptionID = 'MATLAB:timetable:RowDimNameNondefault';
    end
        
    properties(Constant, Access='protected')
        % Constant properties are not persisted when serialized
        %propertyNames
        %defaultDimNames
        dispRowLabelsHeader = true
    end
        
    properties(Access='protected')
        data 
        
        metaDim
        rowDim
        varDim
        
        % 'Properties' will appear to contain this, as well as the per-row, per-var,
        % and per-dimension properties contained in rowDim, varDim. and metaDim,
        arrayProps
    end
            
    %===========================================================================
    methods
        function t = timetable(varargin)
            nin = nargin();
            numNamedArguments = matlab.lang.internal.countNamedArguments();        
            % initialize the Dim arguments
            % metaDim is not initialized until after checking constructor inputs,
            % and stays uninitialized if requesting an uninitialized timetable
            t.varDim  = matlab.internal.coder.tabular.private.varNamesDim;
            % delay assigning to rowDim as it can be explicit or implicit
            
            if nin == 1 && isa(varargin{1}, 'matlab.internal.coder.datatypes.uninitialized')
                % uninitialized object requested, leave data unset
                return
            end
        
            t = t.initializeArrayProps();    
        
            if nin == 0   % zero input case
                % set data, rowDim, and varDim to empty
                t.rowDim = matlab.internal.coder.tabular.private.explicitRowTimesDim(...
                    0, datetime.fromMillis(zeros(0,1)));
                t.varDim = t.varDim.createLike(0,{});
                t.metaDim = matlab.internal.coder.tabular.private.metaDim(2,t.defaultDimNames);
                t.data = cell(1,0);
                return
            end
            
            % Count number of data variables and the number of rows, and
            % check each data variable.
            [numVars,numRows] = tabular.countVarInputs(varargin,numNamedArguments);
            
            if numVars < nin
                pnames = {'Size' 'VariableNames' 'VariableTypes' 'RowTimes' 'SampleRate' 'TimeStep' 'StartTime' 'DimensionNames'};
                poptions = struct( ...
                    'CaseSensitivity',false, ...
                    'PartialMatching','first', ...
                    'StructExpand',false);
                % parseParameterInputs allows string param names, but they are
                % not supported in timetable constructor, so scan the parameter
                % names beforehand and error if necessary. If the user had
                % supplied any parameters using the Name=Value syntax then those
                % names would be strings but we want to allow those, so skip the
                % error check for those and let parseParameterInputs accept
                % those.
                for i = numVars+1:2:(length(varargin) - 2*numNamedArguments)
                    pname = varargin{i};
                    % Missing string is not supported in codegen, so no need to check for
                    % that.
                    coder.internal.errorIf(isstring(pname) && isscalar(pname),...
                        'MATLAB:timetable:StringParamNameNotSupported',pname);
                end
                
                supplied = coder.internal.parseParameterInputs(pnames,poptions,varargin{numVars+1:end});
                
                % If the user supplied 's' as the parameter name, then that
                % would have matched to Size, check if that is the case and
                % error.
                if supplied.Size
                    pname = varargin{numVars+supplied.Size-1};
                    coder.internal.assert(pname ~= "s" && pname ~= "S",...
                        'Coder:toolbox:AmbiguousPartialMatch',pname,"'Size','SampleRate','StartTime'")
                end
                sz = coder.internal.getParameterValue(supplied.Size,[],varargin{numVars+1:end});
                vartypes = coder.internal.getParameterValue(supplied.VariableTypes,{},varargin{numVars+1:end});
                dimnames = coder.internal.getParameterValue(supplied.DimensionNames,t.defaultDimNames,varargin{numVars+1:end});
                rawvarnames = coder.internal.getParameterValue(supplied.VariableNames,{},varargin{numVars+1:end});
                startTime = coder.internal.getParameterValue(supplied.StartTime,seconds(0),varargin{numVars+1:end});
                timeStep = coder.internal.getParameterValue(supplied.TimeStep,[],varargin{numVars+1:end});
                sampleRate = coder.internal.getParameterValue(supplied.SampleRate,[],varargin{numVars+1:end});
                
                % Only assign value to rowtimes if RowTimes were supplied,
                % otherwise we will assign the value later.
                if supplied.RowTimes
                    rowtimes = coder.internal.getParameterValue(supplied.RowTimes,[],varargin{numVars+1:end});
                end
                [rowtimesDefined,startTime,timeStep,sampleRate] = ...
                    matlab.internal.coder.tabular.validateTimeVectorParams(...
                    supplied.RowTimes ~= 0,startTime,supplied.StartTime ~= 0,timeStep,supplied.TimeStep ~= 0,sampleRate,supplied.SampleRate ~= 0);
                
            else
                supplied.Size = uint32(0);
                supplied.VariableTypes = uint32(0);
                supplied.VariableNames = uint32(0);
                supplied.RowTimes = uint32(0);
                supplied.SampleRate = uint32(0);
                supplied.TimeStep = uint32(0);
                rowtimesDefined = uint32(0);
                dimnames = t.defaultDimNames;
                rawvarnames = {};
            end
            
            % Verify that dimension names and variable names are constant.
            coder.internal.assert(coder.internal.isConst(rawvarnames), ...
                                    'MATLAB:table:NonconstantVariableNames');
            coder.internal.assert(coder.internal.isConst(dimnames), ...
                                    'MATLAB:table:NonconstantDimensionNames');
            
            if coder.const(supplied.Size) % preallocate from specified size and var types
                % If using 'Size' parameter, cannot have data variables as inputs
                coder.internal.errorIf(numVars > 0, 'MATLAB:table:InvalidSizeSyntax');
                coder.internal.assert(matlab.internal.datatypes.isIntegerVals(sz,0) && isequal(numel(sz),2), ...
                    'MATLAB:table:InvalidSize');
                % in table preallocation, types must be constant
                coder.internal.assert(coder.internal.isConst(vartypes), 'MATLAB:table:NonconstantVariableTypes');
                sz = double(sz);
                
                coder.internal.assert(supplied.VariableTypes ~= 0 || sz(2) == 0, ...
                    'MATLAB:table:MissingVariableTypes');
                coder.internal.errorIf(supplied.VariableTypes ~= 0 && ~matlab.internal.coder.datatypes.isText(vartypes,true), ...
                    'MATLAB:table:InvalidVariableTypes');
                coder.internal.assert(isequal(sz(2), numel(vartypes)), ...
                    'MATLAB:table:VariableTypesAndSizeMismatch');
                % RowTimes, TimeStep, or SampleRate must be provided
                % in the preallocation syntax.
                coder.internal.assert(rowtimesDefined, ...
                    'MATLAB:timetable:NoTimeVectorPreallocation');
                
                numRows = sz(1); numVars = numel(vartypes);
                vars = tabular.createVariables(vartypes, numRows, numVars);
                
                if supplied.TimeStep || supplied.SampleRate
                    % Create an internally-optimized timetable unless the
                    % row times parameters are unreasonable.
                    [makeImplicit,rowtimes] = matlab.internal.coder.tabular.private.implicitRegularRowTimesDim.implicitOrExplicit(...
                        numRows,startTime,timeStep,sampleRate);
                    if ~coder.internal.isConst(makeImplicit) || makeImplicit
                        coder.internal.assert(makeImplicit, 'MATLAB:timetable:CannotBeImplicit');
                        rowDimTemplate = matlab.internal.coder.tabular.private.implicitRegularRowTimesDim(...
                            numRows,startTime,timeStep,sampleRate);
                    else
                        rowDimTemplate  = matlab.internal.coder.tabular.private.explicitRowTimesDim;
                    end
                else
                    rowDimTemplate  = matlab.internal.coder.tabular.private.explicitRowTimesDim;
                end
                
                if ~supplied.VariableNames
                    % Create default var names, which never conflict with
                    % the default row times name.
                    varnames = cell(1,coder.const(numVars));
                    for i = 1:numVars
                        varnames{i} = t.varDim.dfltLabels(i,true);
                    end
                else
                    varnames = rawvarnames;
                end
                
            else % create from data variables
                varnames = rawvarnames;

                if supplied.VariableTypes
                    arg1 = varargin{1};
                    % Check for the case with no 'Size' param, but it
                    % may have been provided as "Size". Be helpful for
                    % that specific case.
                    stringsize = (numVars == 2) && (numRows == 1) && ...
                        isstring(arg1) && isscalar(arg1) && startsWith("size",arg1,'IgnoreCase',true); % partial case-insensitive
                    coder.internal.errorIf(stringsize, 'MATLAB:timetable:StringParamNameNotSupported',arg1);
                    % VariableTypes may not be supplied with data variables
                    coder.internal.errorIf(~stringsize, 'MATLAB:table:IncorrectVariableTypesSyntax');
                end
                
                if rowtimesDefined
                    
                    vars = cell(1,numVars);
                    for i = 1:numVars
                        vars{i} = varargin{i};
                    end
                    
                    if supplied.RowTimes
                        if numVars == 0
                            % Create an Nx0 timetable as tall as the specified row times
                            numRows = length(rowtimes);
                        end
                        rowDimTemplate  = matlab.internal.coder.tabular.private.explicitRowTimesDim;
                    else % supplied.TimeStep || supplied.SampleRate
                        % Create an internally-optimized timetable unless
                        % the row times parameters are unreasonable.
                        [makeImplicit,rowtimes] = matlab.internal.coder.tabular.private.implicitRegularRowTimesDim.implicitOrExplicit(...
                            numRows,startTime,timeStep,sampleRate);
                        if ~coder.internal.isConst(makeImplicit) || makeImplicit
                            coder.internal.assert(makeImplicit, 'MATLAB:timetable:CannotBeImplicit');
                            rowDimTemplate = matlab.internal.coder.tabular.private.implicitRegularRowTimesDim(...
                                numRows,startTime,timeStep,sampleRate);
                        else
                            rowDimTemplate  = matlab.internal.coder.tabular.private.explicitRowTimesDim;
                        end
                    end
                else
                    % Neither RowTimes, TimeStep, nor SampleRate was specified, get the row times from first data arg
                    coder.internal.errorIf(numVars == 0,'MATLAB:timetable:NoTimeVector');
                    rowtimes = varargin{1};
                    if ~isa(rowtimes,'datetime') && ~isa(rowtimes,'duration') || ~isvector(rowtimes)
                        tableinput = numVars == 1 && istabular(rowtimes);
                        coder.internal.errorIf(tableinput, 'MATLAB:timetable:NoTimeVectorTableInput');
                        coder.internal.errorIf(~tableinput, 'MATLAB:timetable:NoTimeVector');
                    end
                    numVars = numVars - 1; % don't count time index in vars
                    vars = cell(1,numVars);
                    for i = 1:numVars
                        vars{i} = varargin{i+1};
                    end
                    rowDimTemplate  = matlab.internal.coder.tabular.private.explicitRowTimesDim;
                end
                
                % codegen requires specifying variable names
                coder.internal.assert(supplied.VariableNames ~= 0 || numVars==0, 'MATLAB:table:MissingVariableNames');
            end
            
            % handle string (scalar) inputs
            if isstring(varnames)
                varnames_cellstr = cellstr(varnames);
            else
                varnames_cellstr = varnames;
            end
            if isstring(dimnames)
                dimnames_cellstr = cellstr(dimnames);
            else
                dimnames_cellstr = dimnames;
            end
            t = t.initInternals(vars, numRows, rowtimes, numVars, varnames_cellstr, ...
                dimnames_cellstr, rowDimTemplate);
           
            % Detect conflicts between the var names and the default dim names.
            t.metaDim = t.metaDim.checkAgainstVarLabels(varnames_cellstr);
        end
    end
    
    %===========================================================================
    methods(Hidden) % hidden methods block
        function props = getProperties(t)
            % call the same method in the superclass first
            props = t.getProperties@matlab.internal.coder.tabular();
            % now do the duration properties and assign directly to the
            % internal proeprties
            p = t.rowDim.getDurationProperties();
            props.RowTimes_I = p.RowTimes;
            props.StartTime_I = p.StartTime;
            props.TimeStep_I = p.TimeStep;
        end
        
        function t = setProperties(t,s)
            %SET Set some or all table properties from a scalar struct or properties object.
            % This function is for internal use only and will change in a future release.
            % Do not use this function. Use t.Properties instead.
            
            if isstruct(s) && isscalar(s)
                fnames = fieldnames(s);
            else
                coder.internal.assert(isa(s, 'matlab.internal.coder.tabular.TimetableProperties'), ...
                    'MATLAB:table:InvalidPropertiesAssignment','TimetableProperties',class(t));
                fnames = t.propertyNames;
            end
            % fnames must be constant
            coder.const(fnames);
            
            % Set only a sensible subset of these properties. The assignment
            % precedence is based on the assumption that all four properties are
            % present and "in sync", and if so this creates an optimized regular
            % result when that's possible. If not in sync, it still follows the
            % same precedence, but the assignment is ill-defined and the result
            % may not be as intended. StartTime is assigned when present and either
            % SampleRate or TimeStep are assigned.
            haveRowTimes = false;
            haveSampleRate = false;
            haveTimeStep = false;
            haveStartTime = false;
            for i = 1:numel(fnames)
                switch fnames{i}
                    case 'RowTimes'
                        haveRowTimes = true;
                    case 'SampleRate'
                        haveSampleRate = true;
                    case 'TimeStep'
                        haveTimeStep = true;
                    case 'StartTime'
                        haveStartTime = true;
                end
            end
            useRowTimes   = false;
            useSampleRate = false;
            useTimeStep   = false;
            
            currTimeStep = t.rowDim.timeStep;
            currSampleRate = t.rowDim.sampleRate;
            currRowTimes = t.rowDim.labels;
            
            % * First, prefer an integer SampleRate
            % * Next, prefer a non-NaN TimeStep
            % * Next, prefer a non-NaN SampleRate
            % * Next, prefer explicit row times
            % * Last, set a NaN TimeStep or SampleRate
            % where "prefer" means "use if present"
            if haveSampleRate
                sampleRateChanged = ~isequal(s.SampleRate, currSampleRate);
                if sampleRateChanged && matlab.internal.datatypes.isScalarInt(s.SampleRate) % including 0
                    useSampleRate = true;
                elseif haveTimeStep && ~isequal(s.TimeStep, currTimeStep) && ~isnan(s.TimeStep)
                        
                    % Use the specified non-NaN TimeStep. It might be a duration
                    % or a calendarDuration. It might be finite (including 0) or
                    % Inf, so the result might be regular or irregular.
                    useTimeStep = true;
                elseif sampleRateChanged && ~isnan(s.SampleRate) 
                    % Use the specified non-NaN SampleRate. It might be finite
                    % (including 0) or Inf, so the result might be regular or
                    % irregular.
                    useSampleRate = true;
                elseif haveRowTimes && ~isequal(s.RowTimes, currRowTimes)
                    % NaN SampleRate and TimeStep implies irregular
                    % RowTimes (if in sync).
                    useRowTimes = true;
                elseif haveTimeStep  && ~isequal(s.TimeStep, currTimeStep)
                    % No RowTimes provided, fall back to NaN TimeStep. It might
                    % be a duration or a calendarDuration. Use TimeStep, not
                    % SampleRate, to potentially overwrite an existing non-NaN
                    % calendarDuration TimeStep in t.
                    useTimeStep = true;
                elseif sampleRateChanged
                    % No TimeStep or RowTimes provided, fall back to NaN SampleRate.
                    useSampleRate = true;
                end
            elseif haveTimeStep
                % No SampleRate provided, fall back to TimeStep or RowTimes.
                timeStepChanged = ~isequal(s.TimeStep, currTimeStep);
                if timeStepChanged && ~isnan(s.TimeStep)
                    % Use the specified non-NaN TimeStep. It might be a duration
                    % or a calendarDuration. It might be finite (including 0) or
                    % Inf, so the result might be regular or irregular.
                    useTimeStep = true;
                elseif haveRowTimes && ~isequal(s.RowTimes, currRowTimes)
                    % NaN TimeStep implies irregular RowTimes (if in sync).
                    useRowTimes = true;
                elseif timeStepChanged
                    % No RowTimes, fall back to NaN TimeStep.
                    useTimeStep = true;
                end
            elseif haveRowTimes && ~isequal(s.RowTimes, currRowTimes)
                % No SampleRate or TimeStep, fall back to RowTimes if we have
                % them. The result might be regular or irregular.
                useRowTimes = true;
            end
            
            % Set the necessary properties, as determined above, in the rowDim.
            if useRowTimes
                t.rowDim = t.rowDim.setLabels(s.RowTimes, [], t.rowDimLength());
            else
                if haveRowTimes && (numel(s.RowTimes) ~= t.rowDimLength())
                    t.rowDim.setLabels(s.RowTimes, [], t.rowDimLength()); % call just to get the error handling
                end
                if useSampleRate, t.rowDim = t.rowDim.setSampleRate(s.SampleRate); end
                if useTimeStep, t.rowDim = t.rowDim.setTimeStep(s.TimeStep); end
                if haveStartTime, t.rowDim = t.rowDim.setStartTime(s.StartTime); end
            end
            
            % Remove the row-times-related properties form the input, and call
            % the superclass method to set the remaining properties.
            sstruct = struct();
            coder.unroll();
            for i = 1:numel(fnames)
                if ~any(strcmp(fnames{i}, {'RowTimes', 'SampleRate', 'StartTime', 'TimeStep'}))
                    sstruct.(fnames{i}) = s.(fnames{i});
                end
            end
            t = t.setProperties@matlab.internal.coder.tabular(sstruct);
        end

        function tf = isImplicitRegular(tt)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            tf = isa(tt.rowDim,'matlab.internal.coder.tabular.private.implicitRegularRowTimesDim');
        end
    end

    %===========================================================================
    methods(Hidden, Static)
        function t = init(vars, numRows, rowTimes, numVars, varNames, dimNames)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.

            % INIT creates a timetable from data and metadata.  It bypasses the input parsing
            % done by the constructor, but still checks the metadata.
            t = matlab.internal.coder.timetable(matlab.internal.coder.datatypes.uninitialized());
            rowDimTemplate  = matlab.internal.coder.tabular.private.explicitRowTimesDim;
            if nargin == 6
                t = t.initInternals(vars, numRows, rowTimes, numVars, varNames, dimNames, rowDimTemplate);
            else
                t = t.initInternals(vars, numRows, rowTimes, numVars, varNames,t.defaultDimNames, rowDimTemplate);
            end
            if numVars > 0
                t.metaDim = t.metaDim.checkAgainstVarLabels(t.varDim.labels);
            end
            t = t.initializeArrayProps();
        end
        
        function t = initRegular(vars, numRows, startTime, timeStep, sampleRate, numVars, varNames, dimNames)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            % INITREGULAR (tries to) create an optimized regular timetable from
            % data and metadata.  It bypasses the input parsing done by the
            % constructor, but still checks the metadata.
            
            t = matlab.internal.coder.timetable(matlab.internal.coder.datatypes.uninitialized());
            % If the row times parameters are reasonable, create a row dim with
            % the specified row times parameters, initInternals does the rest.
            % There is little error checking on those parameters, the caller
            % should use validateTimeVectorParams. If the parameters are not
            % reasonable, leave the existing explicitRowTimesDim in place, and
            % use the row times vector constructed by implicitOrExplicit.
            [makeImplicit,rowtimes] = matlab.internal.coder.tabular.private.implicitRegularRowTimesDim.implicitOrExplicit(...
                numRows,startTime,timeStep,sampleRate);
            if ~coder.internal.isConst(makeImplicit) || makeImplicit
                coder.internal.assert(makeImplicit, 'MATLAB:timetable:CannotBeImplicit');
                rowDimTemplate = matlab.internal.coder.tabular.private.implicitRegularRowTimesDim(...
                    numRows,startTime,timeStep,sampleRate);
            else
                rowDimTemplate = matlab.internal.coder.tabular.private.explicitRowTimesDim;
            end
            if nargin == 8
                t = t.initInternals(vars,numRows,rowtimes,numVars,varNames,dimNames,rowDimTemplate);
            else
                t = t.initInternals(vars,numRows,rowtimes,numVars,varNames,t.defaultDimNames,rowDimTemplate);
            end
            if numVars > 0
                t.metaDim = t.metaDim.checkAgainstVarLabels(t.varDim.labels);
            end
            t = t.initializeArrayProps();
        end
        
        function name = matlabCodegenUserReadableName
            % Make this look like a timetable (not the redirected timetable) in the codegen report
            name = 'timetable';
        end

        function t = matlabCodegenTypeof(coderType)
            if strcmp(coderType.Properties.rowDim.ClassName, ...
                    'matlab.internal.coder.tabular.private.explicitRowTimesDim')
                t = 'matlab.coder.type.TimetableType';
            else
                t = 'matlab.coder.type.RegularTimetableType';
            end
        end

    end % hidden static methods block
    
    %===========================================================================
    methods(Access = 'protected')  
        function b = cloneAsEmpty(~)            
        %CLONEASEMPTY Create a new empty timetable from an existing one.
                b = timetable(matlab.internal.coder.datatypes.uninitialized());
        end
        
        % used by varfun and rowfun
        function id = specifyInvalidOutputFormatID(~,funName)
            id = ['MATLAB:timetable:' funName ':InvalidOutputFormat'];
        end

        function errID = throwSubclassSpecificErrorIf(obj,cond,msgid,varargin)
            % Throw the timetable version of the msgid error, using varargin as the
            % variables to fill the holes in the message.
            errID = throwSubclassSpecificErrorIf@matlab.internal.coder.tabular(obj,['timetable:' msgid]);
            coder.internal.errorIf(nargout == 0 && cond,errID,varargin{:});
        end
    end % protected methods block
    
    %===========================================================================
    methods (Access = 'private', Static)
        function propNames = getPropertyNamesList()
            arrayPropsMod = fieldnames(matlab.internal.coder.tabular.arrayPropsDflts);
            propNames = [arrayPropsMod; ...
                matlab.internal.coder.tabular.private.metaDim.propertyNames; ...
                matlab.internal.coder.tabular.private.varNamesDim.propertyNames; ...
                matlab.internal.coder.tabular.private.rowTimesDim.propertyNames];
        end
    end
    
    %===========================================================================
    methods(Hidden, Access={?hTestImplicitVsExplicitRowTimes})
        
        function tf = isSpecifiedAsRate(tt)
            tf = tt.rowDim.isSpecifiedAsRate();
        end
    end
    
    %===========================================================================    
    methods(Hidden, Static)
        function out = matlabCodegenFromRedirected(t)

            varnames = t.varDim.labels;
            dimnames = t.metaDim.labels;
            if isImplicitRegular(t)
                starttime = t.rowDim.startTime;
                if isSpecifiedAsRate(t)
                    samplerate = t.rowDim.sampleRate;
                    timestep = []; % use sampleRate, set timeStep to empty
                else
                    samplerate = [];  % use timeStep, set sampleRate to empty
                    timestep = t.rowDim.timeStep;
                end
                out = timetable.initRegular(t.data,t.rowDim.length,starttime,timestep, ...
                    samplerate, t.varDim.length, varnames, dimnames);
            else
                rowtimes = t.rowDim.labels;    
                out = timetable.init(t.data,t.rowDim.length,rowtimes,t.varDim.length,...
                    varnames,dimnames);
            end

            % Reuse matlabCodegenFromRedirected static method in
            % TimetableProperties to convert the properties
            tableprops = matlab.internal.coder.tabular.TimetableProperties.matlabCodegenFromRedirected(...
                getProperties(t));            
            out.Properties.Description = tableprops.Description;
            out.Properties.UserData = tableprops.UserData;
            out.Properties.VariableDescriptions = tableprops.VariableDescriptions;
            out.Properties.VariableUnits = tableprops.VariableUnits;
            out.Properties.VariableContinuity = tableprops.VariableContinuity;
        end
        
        function out = matlabCodegenToRedirected(t)
            
            data = varfun(@(x) x, t, 'OutputFormat', 'cell');
            varnames = t.Properties.VariableNames;
            dimnames = t.Properties.DimensionNames;
            if isImplicitRegular(t)
                starttime = t.Properties.StartTime;
                if isSpecifiedAsRate(t)
                    samplerate = t.Properties.SampleRate;
                    timestep = []; % use sampleRate, set timeStep to empty
                else
                    samplerate = [];  % use timeStep, set sampleRate to empty
                    timestep = t.Properties.TimeStep;
                end
                
                out = matlab.internal.coder.timetable.initRegular(data,...
                    size(t,1),starttime,timestep, ...
                    samplerate, size(t,2), varnames, dimnames);
            else
                rowtimes = t.Properties.RowTimes;
                out = matlab.internal.coder.timetable.init(data,size(t,1),...
                    rowtimes,size(t,2),varnames,dimnames);
            end
            
            propsIn = getProperties(t);
            if ~isempty(propsIn.VariableDescriptions)
                out.varDim = out.varDim.setDescrs(propsIn.VariableDescriptions);
            end
            if ~isempty(propsIn.VariableUnits)
                out.varDim = out.varDim.setUnits(propsIn.VariableUnits);
            end
            if ~isempty(propsIn.VariableContinuity)
                out.varDim = out.varDim.setContinuity(cellstr(propsIn.VariableContinuity));
            end
            out = out.setDescription(propsIn.Description);
            out = out.setUserData(propsIn.UserData);
        end
    end
    
    methods(Static, Access = 'protected')
        function props = getEmptyProperties()
            props = matlab.internal.coder.tabular.TimetableProperties;
        end
    end

    % Unsupported methods that simply return an error message
    methods(Hidden)
        function varargout = addprop(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'addprop', 'timetable');
        end

        function varargout = containsrange(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'containsrange', 'timetable');
        end

        function varargout = head(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'head', 'timetable');
        end

        function varargout = inner2outer(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'inner2outer', 'timetable');
        end

        function varargout = isequal(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'isequal', 'timetable');
        end

        function varargout = lag(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'lag', 'timetable');
        end

        function varargout = overlapsrange(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'overlapsrange', 'timetable');
        end

        function varargout = repelem(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'repelem', 'timetable');
        end

        function varargout = rmprop(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'rmprop', 'timetable');
        end

        function varargout = rowfun(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'rowfun', 'timetable');
        end

        function varargout = rows2vars(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'rows2vars', 'timetable');
        end

        function varargout = summary(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'summary', 'timetable');
        end

        function varargout = tail(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'tail', 'timetable');
        end

        function varargout = topkrows(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'topkrows', 'timetable');
        end

        function varargout = withinrange(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'withinrange', 'timetable');
        end

        function disp(varargin)
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'disp', 'timetable');
        end
    end

    % Unsupported methods: unary elementwise functions
    methods(Hidden)
        function varargout = ceil(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'ceil', 'timetable');
        end

        function varargout = floor(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'floor', 'timetable');
        end

        function varargout = fix(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'fix', 'timetable');
        end

        function varargout = round(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'round', 'timetable');
        end

        function varargout = abs(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'abs', 'timetable');
        end

        function varargout = cos(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cos', 'timetable');
        end

        function varargout = cosd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cosd', 'timetable');
        end

        function varargout = cosh(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cosh', 'timetable');
        end

        function varargout = cospi(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cospi', 'timetable');
        end

        function varargout = acos(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acos', 'timetable');
        end

        function varargout = acosd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acosd', 'timetable');
        end

        function varargout = acosh(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acosh', 'timetable');
        end

        function varargout = cot(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cot', 'timetable');
        end

        function varargout = cotd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cotd', 'timetable');
        end

        function varargout = coth(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'coth', 'timetable');
        end

        function varargout = acot(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acot', 'timetable');
        end

        function varargout = acotd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acotd', 'timetable');
        end

        function varargout = acoth(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acoth', 'timetable');
        end

        function varargout = csc(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'csc', 'timetable');
        end

        function varargout = cscd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cscd', 'timetable');
        end

        function varargout = csch(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'csch', 'timetable');
        end

        function varargout = acsc(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acsc', 'timetable');
        end

        function varargout = acscd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acscd', 'timetable');
        end

        function varargout = acsch(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acsch', 'timetable');
        end

        function varargout = sec(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sec', 'timetable');
        end

        function varargout = secd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'secd', 'timetable');
        end

        function varargout = sech(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sech', 'timetable');
        end

        function varargout = asec(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'asec', 'timetable');
        end

        function varargout = asecd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'asecd', 'timetable');
        end

        function varargout = asech(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'asech', 'timetable');
        end

        function varargout = sin(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sin', 'timetable');
        end

        function varargout = sind(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sind', 'timetable');
        end

        function varargout = sinh(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sinh', 'timetable');
        end

        function varargout = sinpi(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sinpi', 'timetable');
        end

        function varargout = asin(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'asin', 'timetable');
        end

        function varargout = asind(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'asind', 'timetable');
        end

        function varargout = asinh(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'asinh', 'timetable');
        end

        function varargout = tan(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'tan', 'timetable');
        end

        function varargout = tand(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'tand', 'timetable');
        end

        function varargout = tanh(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'tanh', 'timetable');
        end

        function varargout = atan(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'atan', 'timetable');
        end

        function varargout = atand(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'atand', 'timetable');
        end

        function varargout = atan2(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'atan2', 'timetable');
        end

        function varargout = atan2d(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'atan2d', 'timetable');
        end

        function varargout = atanh(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'atanh', 'timetable');
        end

        function varargout = exp(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'exp', 'timetable');
        end

        function varargout = expm1(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'expm1', 'timetable');
        end

        function varargout = log(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'log', 'timetable');
        end

        function varargout = log10(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'log10', 'timetable');
        end

        function varargout = log1p(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'log1p', 'timetable');
        end

        function varargout = log2(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'log2', 'timetable');
        end

        function varargout = reallog(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'reallog', 'timetable');
        end

        function varargout = power(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'power', 'timetable');
        end

        function varargout = pow2(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'pow2', 'timetable');
        end

        function varargout = nextpow2(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'nextpow2', 'timetable');
        end

        function varargout = nthroot(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'nthroot', 'timetable');
        end

        function varargout = sqrt(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sqrt', 'timetable');
        end

        function varargout = realpow(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'realpow', 'timetable');
        end

        function varargout = realsqrt(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'realsqrt', 'timetable');
        end
    end % Unsupported methods: unary elementwise functions

    % Unsupported methods: binary elementwise functions
    methods(Hidden)
        function varargout = plus(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'plus', 'timetable');
        end

        function varargout = minus(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'minus', 'timetable');
        end

        function varargout = eq(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'eq', 'timetable');
        end

        function varargout = ne(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'ne', 'timetable');
        end

        function varargout = ge(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'ge', 'timetable');
        end

        function varargout = gt(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'gt', 'timetable');
        end

        function varargout = le(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'le', 'timetable');
        end

        function varargout = lt(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'lt', 'timetable');
        end

        function varargout = and(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'and', 'timetable');
        end

        function varargout = or(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'or', 'timetable');
        end

        function varargout = not(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'not', 'timetable');
        end

        function varargout = xor(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'xor', 'timetable');
        end

        function varargout = ldivide(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'ldivide', 'timetable');
        end

        function varargout = rdivide(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'rdivide', 'timetable');
        end

        function varargout = times(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'times', 'timetable');
        end

        function varargout = mod(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'mod', 'timetable');
        end

        function varargout = rem(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'rem', 'timetable');
        end

    end % Unsupported methods: binary elementwise functions

    % Unsupported methods: aggregation functions
    methods(Hidden)
        function varargout = max(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'max', 'timetable');
        end

        function varargout = min(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'min', 'timetable');
        end

        function varargout = mean(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'mean', 'timetable');
        end

        function varargout = median(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'median', 'timetable');
        end

        function varargout = mode(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'mode', 'timetable');
        end

        function varargout = std(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'std', 'timetable');
        end

        function varargout = var(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'var', 'timetable');
        end

        function varargout = diff(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'diff', 'timetable');
        end

        function varargout = prod(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'prod', 'timetable');
        end

        function varargout = sum(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sum', 'timetable');
        end

        function varargout = cummax(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cummax', 'timetable');
        end

        function varargout = cummin(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cummin', 'timetable');
        end

        function varargout = cumprod(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cumprod', 'timetable');
        end

        function varargout = cumsum(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cumsum', 'timetable');
        end
    end % Unsupported methods: aggregation functions
end

%-------------------------------------------------------------------------------
function names = dfltTimetableDimNames()
names = { getString(message('MATLAB:timetable:uistrings:DfltRowDimName')) ...
          getString(message('MATLAB:timetable:uistrings:DfltVarDimName')) };
end
