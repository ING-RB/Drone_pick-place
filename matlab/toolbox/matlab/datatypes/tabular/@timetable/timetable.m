classdef  (AllowedSubclasses = ?eventtable, InferiorClasses = ?table) timetable < tabular
%

%   Copyright 2016-2024 The MathWorks, Inc.
        
    properties(Constant, GetAccess='protected')
        defaultDimNames = dfltTimetableDimNames();
        dispRowLabelsHeader = true;
    end
        
    properties(Transient, SetAccess='protected', GetAccess={?tabular,?matlab.internal.tabular.private.subscripter,?internal.matlab.variableeditor.TimeTableDataModel, ?matlab.internal.editor.interactiveVariables.InteractiveTablesPackager})
        data = cell(1,0);
        
        metaDim = matlab.internal.tabular.private.metaDim(2,timetable.defaultDimNames);
        rowDim  = matlab.internal.tabular.private.explicitRowTimesDim(0,datetime.empty(0,1));
        varDim  = matlab.internal.tabular.private.varNamesDim(0);
        
        % 'Properties' will appear to contain this, as well as the per-row, per-var,
        % and per-dimension properties contained in rowDim, varDim. and metaDim,
        
        arrayProps = timetable.arrayPropsDflts;
    end
            
    %===========================================================================
    methods
        function t = timetable(varargin)
            import matlab.internal.datatypes.isText
            import matlab.internal.datatypes.isIntegerVals
            import matlab.internal.tabular.validateTimeVectorParams
            import matlab.internal.tabular.private.implicitRegularRowTimesDim
            import matlab.internal.datatypes.parseArgsTabularConstructors
            import matlab.lang.internal.countNamedArguments
        
            if nargin == 0
                % Nothing to do
            else
                % Get the count of Name=Value arguments in varargin.
                try
                    numNamedArguments = countNamedArguments();
                catch
                    % If countNamedArguments fails, revert back to old behavior
                    % and assume that none of the NV pairs were passed in as
                    % Name=Value.
                    numNamedArguments = 0;    
                end
                
                % Count number of data variables and the number of rows, and
                % check each data variable.
                [numVars,numRows,nvpairs] = tabular.countVarInputs(varargin,'MATLAB:timetable:StringParamNameNotSupported',numNamedArguments);
                
                if numVars < nargin
                    pnames = {'Size' 'VariableTypes' 'VariableNames'  'DimensionNames' 'RowTimes' 'SampleRate'  'TimeStep'   'StartTime'};
                    dflts =  {    []              {}              {}                {}         []          []          []    seconds(0) };
                    partialMatchPriority = [0 0 1 0 0 1 0 1]; % 'Var' -> 'VariableNames' (backward compat), 'Sa' -> 'SampleRate', 'S' -> ambiguous
                    try
                        [sz,vartypes,varnames,dimnames,rowtimes,sampleRate,timeStep,startTime,supplied] ...
                            = parseArgsTabularConstructors(pnames, dflts, partialMatchPriority, ...
                                                           'MATLAB:timetable:StringParamNameNotSupported', ...
                                                           nvpairs{:});
                    catch ME
                        % The inputs included a 1xM char row that was interpreted as the
                        % start of param name/value pairs, but something went wrong. If
                        % all of the preceding inputs had one row, the WrongNumberArgs
                        % or BadParamName (when the unrecognized name was first among
                        % params) errors suggest that the char row might have been
                        % intended as data. Suggest alternative options in that case.
                        % Only suggest this alternative if the char row vector
                        % did not come from Name=Value.
                        errIDs = ["MATLAB:table:parseArgs:WrongNumberArgs" ...
                                  "MATLAB:table:parseArgs:BadParamNamePossibleCharRowData"];
                        if matches(ME.identifier,errIDs)
                            namedArgumentsStart = nargin - 2*numNamedArguments + 1;
                            if ((numVars == 0) || (numRows == 1)) && (namedArgumentsStart > numVars+1)
                                pname1 = varargin{numVars+1}; % always the first char row vector
                                ME = ME.addCause(MException(message('MATLAB:table:ConstructingFromCharRowData',pname1)));
                            end
                        end
                        % 'StringParamNameNotSupported' suggests the opposite: a 1-row string intended as a param.
                        throw(ME);
                    end
                    [rowtimesDefined,rowtimes,startTime,timeStep,sampleRate] = ...
                        validateTimeVectorParams(supplied,rowtimes,startTime,timeStep,sampleRate);
                else
                    supplied.Size = false;
                    supplied.VariableTypes = false;
                    supplied.VariableNames = false;
                    supplied.DimensionNames = false;
                    supplied.RowTimes = false;
                    supplied.TimeStep = false;
                    supplied.StartTime = false;
                    rowtimesDefined = false;
                end

                if supplied.Size % preallocate from specified size and var types
                    if numVars > 0
                        % If using 'Size' parameter, cannot have data variables as inputs
                        error(message('MATLAB:table:InvalidSizeSyntax'));                    
                    elseif ~isIntegerVals(sz,0) || ~isequal(numel(sz),2)
                        error(message('MATLAB:table:InvalidSize'));
                    end
                    sz = double(sz);
                    
                    if sz(2) == 0
                        % If numVars is 0, VariableTypes must be empty (or not supplied)
                        if ~isequal(numel(vartypes),0)
                            error(message('MATLAB:table:VariableTypesAndSizeMismatch'))
                        end
                    elseif ~supplied.VariableTypes && (sz(2) > 0)
                        error(message('MATLAB:table:MissingVariableTypes'));
                    elseif ~isText(vartypes,true) % Don't allow char row vector.
                        error(message('MATLAB:table:InvalidVariableTypes'));
                    elseif ~isequal(sz(2), numel(vartypes))
                        error(message('MATLAB:table:VariableTypesAndSizeMismatch'))
                    elseif ~rowtimesDefined
                        % RowTimes, TimeStep, or SampleRate must be provided
                        % in the preallocation syntax.
                        error(message('MATLAB:timetable:NoTimeVectorPreallocation'));
                    end
                    
                    numRows = sz(1); numVars = sz(2);
                    vars = tabular.createVariables(vartypes,sz);
                    
                    if supplied.TimeStep || supplied.SampleRate
                        % Create an internally-optimized timetable unless the
                        % row times parameters are unreasonable.
                        [makeImplicit,rowtimes] = implicitRegularRowTimesDim.implicitOrExplicit(numRows,startTime,timeStep,sampleRate);
                        if makeImplicit
                            t.rowDim = implicitRegularRowTimesDim(numRows,startTime,timeStep,sampleRate);
                        end
                    end
                    
                    if ~supplied.VariableNames
                        % Create default var names, which never conflict with
                        % the default row times name.
                        varnames = t.varDim.dfltLabels(1:numVars);
                    end
                    
                else % create from data variables
                    if supplied.VariableTypes
                        if (numVars == 2) && (numRows == 1)
                            % Apparently no 'Size' param, but it may have been provided as
                            % "Size". Be helpful for that specific case.
                            arg1 = varargin{1};
                            if isstring(arg1) && isscalar(arg1) && startsWith("size",arg1,'IgnoreCase',true) % partial case-insensitive
                                error(message('MATLAB:timetable:StringParamNameNotSupported',arg1));
                            end
                        end
                        % VariableTypes may not be supplied with data variables
                        error(message('MATLAB:table:IncorrectVariableTypesSyntax'));
                    end
                    
                    vars = varargin(1:numVars);
                    
                    if ~supplied.VariableNames
                        % Get the workspace names of the input arguments from inputname if
                        % variable names were not provided. Need these names before looking
                        % through vars for the time vector.
                        varnames = repmat({''},1,numVars);
                        for i = 1:numVars, varnames{i} = inputname(i); end
                    end
                
                    if rowtimesDefined 
                        rowtimesName = {}; % use the default name
                        if supplied.RowTimes
                            if numVars == 0
                                % Create an Nx0 timetable as tall as the specified row times
                                numRows = length(rowtimes);
                            end
                        else % supplied.TimeStep || supplied.SampleRate
                            % Create an internally-optimized timetable unless
                            % the row times parameters are unreasonable.
                            [makeImplicit,rowtimes] = implicitRegularRowTimesDim.implicitOrExplicit(numRows,startTime,timeStep,sampleRate);
                            if makeImplicit
                                t.rowDim = implicitRegularRowTimesDim(numRows,startTime,timeStep,sampleRate);
                            end
                        end
                    else
                        % Neither RowTimes, TimeStep, nor SampleRate was specified, get the row times from first data arg
                        if numVars == 0
                            % Error if no data args were supplied
                            error(message('MATLAB:timetable:NoTimeVector'));
                        end
                        rowtimes = vars{1};
                        if ~isa(rowtimes,'datetime') && ~isa(rowtimes,'duration') || ~isvector(rowtimes)
                            if numVars == 1 && istabular(vars{1})
                                error(message('MATLAB:timetable:NoTimeVectorTableInput'));
                            elseif numVars == 1 && isa(varargin{1},'timeseries')
                                me = MException(message("MATLAB:timetable:ts2timetable"));
                                me = me.addCorrection(matlab.lang.correction.ReplaceIdentifierCorrection('timetable','ts2timetable'));
                                throw(me);
                            elseif numVars == 1 && isa(varargin{1},'Simulink.SimulationData.Dataset')
                                me = MException(message("MATLAB:timetable:extractTimetable"));
                                me = me.addCorrection(matlab.lang.correction.ReplaceIdentifierCorrection('timetable','extractTimetable'));
                                throw(me);                                
                                
                            else
                                error(message('MATLAB:timetable:NoTimeVector'));
                            end
                        end
                        vars(1) = [];
                        numVars = numVars - 1; % don't count time index in vars

                        if ~supplied.VariableNames
                            rowtimesName = varnames{1};
                            varnames(1) = [];
                        else % if supplied.VariableNames && ~supplied.RowTimes
                            % get the row times name from the first input
                            rowtimesName = inputname(1);
                        end

                        if ~isempty(rowtimesName)
                            % If the rows times came from a data input (not from the
                            % RowTimes param), and var names were not provided, get the
                            % row dim name from the inputs. Otherwise, leave the default
                            % row dim name alone.
                            t.metaDim = t.metaDim.setLabels(rowtimesName,1);
                        end
                    end
                    
                    if ~supplied.VariableNames
                        % Fill in default names for data args where inputname couldn't. Do
                        % this after removing the time vector from the other vars, to get the
                        % default names numbered correctly.
                        empties = cellfun('isempty',varnames);
                        if any(empties)
                            varnames(empties) = t.varDim.dfltLabels(find(empties));
                        end
                        % Make sure default names or names from inputname don't conflict.
                        % In this case, both the var names and the row times name are being
                        % detected from the input variable names. Uniqueify duplicates by
                        % appending to the duplicate names
                        varnames = matlab.lang.makeUniqueStrings(varnames,rowtimesName,namelengthmax);
                    end
                end
                
                if supplied.DimensionNames
                    t = t.initInternals(vars, numRows, rowtimes, numVars, varnames, dimnames);
                else
                    t = t.initInternals(vars, numRows, rowtimes, numVars, varnames);
                end
                
                % Detect conflicts between the var names and the default dim names.
                t.metaDim = t.metaDim.checkAgainstVarLabels(varnames);
            end
        end
    end
    
    %===========================================================================
    methods(Hidden) % hidden methods block
        function t = setProperties(t,s)
            %SET Set some or all table properties from a scalar struct or properties object.
            % This function is for internal use only and will change in a future release.
            % Do not use this function. Use t.Properties instead.
            
            import matlab.internal.datatypes.isScalarInt
            import matlab.internal.tabular.private.rowTimesDim
            
            if isstruct(s) && isscalar(s)
                fnames = fieldnames(s);
            elseif isa(s, class(t.emptyPropertiesObj))
                fnames = properties(s);
                % Convert to struct to allow row-times-related properties to be removed later.
                s = struct(s);
            else
                error(message('MATLAB:table:InvalidPropertiesAssignment',class(t.emptyPropertiesObj),class(t)));
            end
            
            % Set only a sensible subset of these properties. The assignment
            % precedence is based on the assumption that all four properties are
            % present and "in sync", and if so this creates an optimized regular
            % result when that's possible. If not in sync, it still follows the
            % same precedence, but the assignment is ill-defined and the result
            % may not be as intended. StartTime is assigned when present and either
            % SampleRate or TimeStep are assigned.
            haveRowTimes = matches("RowTimes",fnames);     useRowTimes   = false;
            haveSampleRate = matches("SampleRate",fnames); useSampleRate = false;
            haveTimeStep = matches("TimeStep",fnames);     useTimeStep   = false;
            haveStartTime = matches("StartTime",fnames);
            
            % * First, prefer an integer SampleRate
            % * Next, prefer a non-NaN TimeStep
            % * Next, prefer a non-NaN SampleRate
            % * Next, prefer explicit row times
            % * Last, set a NaN TimeStep or SampleRate
            % where "prefer" means "use if present"
            if haveSampleRate
                if isScalarInt(s.SampleRate) % including 0
                    useSampleRate = true;
                elseif haveTimeStep && ~isnan(s.TimeStep)
                    % Use the specified non-NaN TimeStep. It might be a duration
                    % or a calendarDuration. It might be finite (including 0) or
                    % Inf, so the result might be regular or irregular.
                    useTimeStep = true;
                elseif ~isnan(s.SampleRate)
                    % Use the specified non-NaN SampleRate. It might be finite
                    % (including 0) or Inf, so the result might be regular or
                    % irregular.
                    useSampleRate = true;
                elseif haveRowTimes
                    % NaN SampleRate and TimeStep implies irregular
                    % RowTimes (if in sync).
                    useRowTimes = true;
                elseif haveTimeStep
                    % No RowTimes provided, fall back to NaN TimeStep. It might
                    % be a duration or a calendarDuration. Use TimeStep, not
                    % SampleRate, to potentially overwrite an existing non-NaN
                    % calendarDuration TimeStep in t.
                    useTimeStep = true;
                else
                    % No TimeStep or RowTimes provided, fall back to NaN SampleRate.
                    useSampleRate = true;
                end
            elseif haveTimeStep
                % No SampleRate provided, fall back to TimeStep or RowTimes.
                if ~isnan(s.TimeStep)
                    % Use the specified non-NaN TimeStep. It might be a duration
                    % or a calendarDuration. It might be finite (including 0) or
                    % Inf, so the result might be regular or irregular.
                    useTimeStep = true;
                elseif haveRowTimes
                    % NaN TimeStep implies irregular RowTimes (if in sync).
                    useRowTimes = true;
                else
                    % No RowTimes, fall back to NaN TimeStep.
                    useTimeStep = true;
                end
            elseif haveRowTimes
                % No SampleRate or TimeStep, fall back to RowTimes if we have
                % them. The result might be regular or irregular.
                useRowTimes = true;
            end
            
            % Set the necessary properties, as determined above, in the rowDim.
            if useRowTimes
                t.rowDim = t.rowDim.setLabels(s.RowTimes);
            else
                if haveRowTimes && (numel(s.RowTimes) ~= t.rowDim.length)
                    t.rowDim.setLabels(s.RowTimes); % call just to get the error handling
                end
                if useSampleRate, t.rowDim = t.rowDim.setSampleRate(s.SampleRate); end
                if useTimeStep, t.rowDim = t.rowDim.setTimeStep(s.TimeStep); end
                if haveStartTime, t.rowDim = t.rowDim.setStartTime(s.StartTime); end
            end
            
            % Remove the row-times-related properties form the input, and call
            % the superclass method to set the remaining properties.
            s = rmfield(s,intersect(fieldnames(s),["RowTimes" "SampleRate" "StartTime" "TimeStep"]));
            t = t.setProperties@tabular(s);
        end

        function tf = eventIndices2timetableIndices(tt,eventIndices)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.

            if nargin < 2
                eventIndices = ':';
            end

            % Get the start and end times of attached events.
            [eventTimes,eventEndTimes] = eventIntervalTimes(tt.rowDim.timeEvents,eventIndices);

            % rowSubsCell is a cell array of logical vectors the same
            % height as the input timetable. This tells you where each
            % attached event occurs in the timetable.
            rowSubsCell = tt.rowDim.eventtimes2timetablesubs(eventTimes,eventEndTimes);

            % Combine each logical vector with an OR operation.
            tf = false(height(tt),1);
            for i = 1:numel(rowSubsCell)
                tf = tf | rowSubsCell{i};
            end
        end

        %% Error stubs
        % Methods to override functions and throw helpful errors
        
        function t = isuniform(t), error(message('MATLAB:datatypes:UseIsRegularMethod',mfilename)); end %#ok<MANU> 
    end % hidden public methods block

    %===========================================================================
    methods(Hidden, Static)
        function t = empty(varargin)
            %

            % Store an empty timetable as a persistent variable for
            % performance.
            persistent ttEmpty

            if isnumeric(ttEmpty) % uninitialized
                ttEmpty = timetable();
            end

            if nargin == 0
                t = ttEmpty;
            else
                sizeOut = size(zeros(varargin{:}));
                if prod(sizeOut) ~= 0
                    error(message('MATLAB:class:emptyMustBeZero'));
                elseif length(sizeOut) > 2
                    error(message('MATLAB:timetable:empty:EmptyMustBeTwoDims'));
                else
                    % Create a 0x0 timetable, and then resize to the correct number
                    % of rows or variables.
                    t = ttEmpty;
                    if sizeOut(1) > 0
                        t.rowDim = t.rowDim.lengthenTo(sizeOut(1));
                    end
                    if sizeOut(2) > 0
                        t.varDim = t.varDim.lengthenTo(sizeOut(2));
                        t.data = cell(1,sizeOut(2)); % assume double
                    end
                end
            end
        end
        
        function t = fromScalarStruct(s,rtimes)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            if ~(isstruct(s) && isscalar(s))
                error(message('MATLAB:table:NonScalarStruct'))
            end
            vars = struct2cell(s)';
            [nrows, nvars] = tabular.validateVarHeights(vars);
            vnames = fieldnames(s);
            if nargin < 2, rtimes = NaT(nrows,1); end % datetime row times by default
            t = timetable.init(vars,nrows,rtimes,nvars,vnames);
        end

        function t = init(vars, numRows, rowTimes, numVars, varNames, dimNames)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            try %#ok<ALIGN>
            
            % INIT creates a timetable from data and metadata.  It bypasses the input parsing
            % done by the constructor, but still checks the metadata.
            t = timetable();
            
            if nargin == 6
                t = t.initInternals(vars, numRows, rowTimes, numVars, varNames, dimNames);
            else
                t = t.initInternals(vars, numRows, rowTimes, numVars, varNames);
            end
            if numVars > 0
                t.metaDim = t.metaDim.checkAgainstVarLabels(t.varDim.labels);
            end
            
            catch ME, throwAsCaller(ME); end
        end
        
        function t = initRegular(vars, numRows, startTime, timeStep, sampleRate, numVars, varNames, dimNames)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            % INITREGULAR (tries to) create an optimized regular timetable from
            % data and metadata.  It bypasses the input parsing done by the
            % constructor, but still checks the metadata.
            
            import matlab.internal.tabular.private.implicitRegularRowTimesDim
            
            try %#ok<ALIGN>
            
            t = timetable();
            % If the row times parameters are reasonable, create a row dim with
            % the specified row times parameters, initInternals does the rest.
            % There is little error checking on those parameters, the caller
            % should use validateTimeVectorParams. If the parameters are not
            % reasonable, leave the existing explicitRowTimesDim in place, and
            % use the row times vector constructed by implicitOrExplicit.
            [makeImplicit,rowtimes] = implicitRegularRowTimesDim.implicitOrExplicit(numRows,startTime,timeStep,sampleRate);
            if makeImplicit
                t.rowDim = implicitRegularRowTimesDim(numRows,startTime,timeStep,sampleRate);
            end
            
            if nargin == 8
                t = t.initInternals(vars,numRows,rowtimes,numVars,varNames,dimNames);
            else
                t = t.initInternals(vars,numRows,rowtimes,numVars,varNames);
            end
            if numVars > 0
                t.metaDim = t.metaDim.checkAgainstVarLabels(t.varDim.labels);
            end
            
            catch ME, throwAsCaller(ME); end
        end

        function tt = createArray(varargin)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            tt = tabular.createArrayImpl(@(fillval)timetable(fillval,RowTimes=NaT),varargin{:});
        end

        % These functions are for internal use only and will change in a
        % future release.  Do not use these functions.
        vOut = makeUniqueVarNames(timetables, timetableNames)
            
    end % hidden static methods block
    
    %===========================================================================
    methods(Access = 'protected')  
        function propNames = propertyNames(t)
            %

            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            persistent names

           if isnumeric(names)
                % Need to manage CustomProperties which are stored in two different
                % places.
                arrayPropsMod = tabular.arrayPropsDflts;
                arrayPropsMod = rmfield(arrayPropsMod, 'TableCustomProperties');
                arrayPropsMod = fieldnames(arrayPropsMod);
                names = [arrayPropsMod; ...
                         t.metaDim.propertyNames; ...
                         t.varDim.propertyNames; ...
                         t.rowDim.propertyNames; ...
                         'CustomProperties'];
            end

            propNames = names;
        end
        
        function p = emptyPropertiesObj(t) %#ok<MANU>
            persistent props 
            
            if isnumeric(props)
                props = matlab.tabular.TimetableProperties;
            end

            p = props;
        end
        
        function b = cloneAsEmpty(a)            
        %

        %CLONEASEMPTY Create a new empty timetable from an existing one.
%             if strcmp(class(a),'timetable') %#ok<STISA>
                % call timetable.empty instead of timetable() for better
                % performance.
                b = timetable.empty;
                b.rowDim = a.rowDim.shortenTo(0);
%             else % b is a subclass of timetable
%                 b = a; % respect the subclass
%                 % leave b.metaDim alone;
%                 b.rowDim = b.rowDim.shortenTo(0);
%                 b.varDim = b.varDim.shortenTo(0);
%                 b.data = cell(1,0);
%                 leave b.arrayProps alone
%             end
        end
        
        function errID = throwSubclassSpecificError(obj,msgid,varargin)
            %

            % THROWSUBCLASSSPECIFICERROR Throw the timetable version of the
            % msgid error, using varargin as the variables to fill the holes in
            % the message.
            errID = throwSubclassSpecificError@tabular(obj,['timetable:' msgid],varargin{:});
            if nargout == 0
                throwAsCaller(errID);
            end
        end
        
        function rowLabelsStruct = summarizeRowLabels(t,stats,statFields,isFcnHandle)
            %

            % SUMMARIZEROWLABELS is called by summary method to get a struct containing
            % a summary of the row labels. For timetable, this includes size, type,
            % time step, time zone, sample rate, start time, and user-specified stats.
            rowTimes = t.rowDim.labels;
            rowLabelsStruct = struct;

            rowLabelsStruct.Size = size(rowTimes);
            rowLabelsStruct.Type = class(rowTimes);

            if isdatetime(rowTimes)
                rowLabelsStruct.TimeZone = rowTimes.TimeZone;
            end
            rowLabelsStruct.SampleRate = t.rowDim.sampleRate;
            rowLabelsStruct.StartTime = t.rowDim.startTime;

            arrayStruct = matlab.internal.math.datasummary(rowTimes,stats,statFields,isFcnHandle,1);
            fdnames = fieldnames(arrayStruct);
            for fd_i = 1:length(fdnames)
                rowLabelsStruct.(fdnames{fd_i}) = arrayStruct.(fdnames{fd_i});
            end
            
            % Time Step
            rowLabelsStruct.TimeStep = t.rowDim.timeStep;
        end

        function h = getDisplayHeader(t,tblName)
            %

            % GETHEADER is called by display method to print the header
            % specific to the tabular subclass. Prints out events link in
            % timetable header if needed.

            h = t.getDisplayHeader@tabular();    
            etSize = size(t.rowDim.timeEvents);
            if  any(etSize)
                eventTblName = tblName + ".Properties.Events";
                msg = getString(message('MATLAB:tabular:DisplayLinkMissingEventsVariable',class(t),tblName));
                % Before trying to display the eventtable attached to the timetable, the link will
                % verify that a timetable with that name exists, and has an attached eventtable.
                codeToExecute = sprintf("if exist('%s','var') && istabular(%s) && isa(%s,'eventtable'),displayWholeObj(%s,'%s'),else,fprintf('%s\\\\n');end", ...
                    tblName, tblName, eventTblName, eventTblName, eventTblName, msg); % multiple levels of escaping needed for the newline
                numEvents = etSize(1);
                if matlab.internal.display.isHot
                    % "with N event/s" with a link
                    if numEvents == 1
                        h = h + " " + getString(message("MATLAB:timetable:UIStringDispHeaderWithOneEventLink",codeToExecute));
                    else
                        h = h + " " + getString(message("MATLAB:timetable:UIStringDispHeaderWithNEventsLink",codeToExecute,numEvents));
                    end
                else
                    % "with N event/s" without a link
                    if numEvents == 1
                        h = h + " " + getString(message("MATLAB:timetable:UIStringDispHeaderWithOneEvent"));
                    else
                        h = h + " " + getString(message("MATLAB:timetable:UIStringDispHeaderWithNEvents",numEvents));
                    end
                end
            end
        end

        function [marginChars,lostWidth,rowLabelsDispWidth,rowDimName,rowDimNameDispWidth,headerIndent,ellipsisIndent] = getRowMargin(t,lostWidth,between,indent,bold)
            %

            % GETROWMARGIN is called by display method to print the row
            % margin specific to the tabular subclass. Prints out
            % annotations for event labels if needed.
            
            import matlab.internal.tabular.display.nSpaces;
            import matlab.internal.tabular.display.boldifyLabels;
            import matlab.internal.tabular.display.vectorizedWrappedLength;
            import matlab.internal.tabular.display.alignTabularContents;
            import matlab.internal.display.truncateLine; 
            
            marginChars = nSpaces(indent);    
            bold = matlab.internal.display.isHot() && bold;
            strongBegin = ''; strongEnd = '';
            if bold
                strongBegin = getString(message('MATLAB:table:localizedStrings:StrongBegin'));
                strongEnd = getString(message('MATLAB:table:localizedStrings:StrongEnd'));
            end
            
            rowlabelChars = string(t.rowDim.textLabels());
            rowlabelChars = matlab.display.internal.vectorizedTruncateLine(rowlabelChars);
            [rowlabelChars,rowLabelsDispWidth,lostWidth] = alignTabularContents(rowlabelChars,lostWidth);

            eventWidth = 0;
            eventLabels =  t.rowDim.textEvents();
            if ~isequal(eventLabels, "")
                [eventLabels, eventWidth,lostWidth] = alignTabularContents(eventLabels,lostWidth);
                eventLabels = eventLabels + nSpaces(between);
                eventWidth = eventWidth + between;
            end

            rowDimName = string(t.metaDim.labels{1});
            rowDimNameDispWidth = ceil(vectorizedWrappedLength(rowDimName));
            if rowLabelsDispWidth < rowDimNameDispWidth
                rowlabelChars = rowlabelChars + nSpaces(rowDimNameDispWidth-rowLabelsDispWidth);
                rowLabelsDispWidth = rowDimNameDispWidth;
            end

            headerIndent = indent + eventWidth;
            ellipsisIndent = indent + eventWidth;
            rowlabelChars = boldifyLabels(rowlabelChars,bold,strongBegin,strongEnd);
            rowDimName = boldifyLabels(rowDimName,bold,strongBegin,strongEnd);
            marginChars = marginChars + eventLabels + rowlabelChars + nSpaces(between);
        end

        function printRowLabelsSummary(t,rowLabelsStruct,detailIsLow)
            %

            % PRINTROWLABELSSUMMARY is called by tabular/summary to print a row labels summary.            
            if matlab.internal.display.isDesktopInUse
                varnameFmt = '<strong>%s</strong>';
            else
                varnameFmt = '%s';
            end

            if isfield(rowLabelsStruct,'Size')
                fprintf('Row Times:\n');
                fprintf(matlab.internal.display.lineSpacingCharacter);
                % Print type only
                fprintf(['    ' varnameFmt ': %s\n'], t.metaDim.labels{1}, rowLabelsStruct.Type);
            end

            if ~detailIsLow && isfield(rowLabelsStruct,'TimeStep')
                sp8 = '        ';
                if ~ismissing(rowLabelsStruct.StartTime)
                    fprintf([sp8 'StartTime:  %s\n'],rowLabelsStruct.StartTime);
                end
                if ~isnan(rowLabelsStruct.TimeStep)
                    fprintf([sp8 'TimeStep:  %s\n'],rowLabelsStruct.TimeStep);
                end
                if ~isnan(rowLabelsStruct.SampleRate)
                    fprintf([sp8 'SampleRate:  %f\n'],rowLabelsStruct.SampleRate);
                end
                if isfield(rowLabelsStruct,'TimeZone') && ~isempty(rowLabelsStruct.TimeZone)
                    fprintf([sp8 'TimeZone:  %s\n'],rowLabelsStruct.TimeZone);
                end
            end
            fprintf('\n');
        end
        
        % Used by varfun and rowfun
        function id = specifyInvalidOutputFormatID(~,funName)
            id = "MATLAB:timetable:" + funName + ":InvalidOutputFormat";
        end
        
        % Used by containsrange, overlapsrange, withinrange
         function [tfRow,ttMin,ttMax,timeSpec] = concurrencyCommon(tt,timeSpec)
            if isa(timeSpec,'timerange')
                timeSpec = timeSpec.convertEventEnds(tt);
            elseif istimetable(timeSpec)
                % Create timerange based on the min/max of the timetable.
                [first,last] = timeSpec.rowDim.getBounds;
                timeSpec = timerange(first,last,'closed');
            elseif isdatetime(timeSpec) || isduration(timeSpec)
                if ~isscalar(timeSpec)
                    error(message('MATLAB:timetable:isconcurrent:InvalidRange'));
                end
                timeSpec = timerange(timeSpec,timeSpec,'closed');
            else
                error(message('MATLAB:timetable:isconcurrent:InvalidRange'));
            end
            
            rowIndices = timeSpec.getSubscripts(tt,'rowDim');
            % Subscript a logical vector rather than the timetable for performance.
            tfRow = false(tt.rowDim.length,1);
            tfRow(rowIndices) = true;
            
            [ttMin, ttMax] = tt.rowDim.getBounds();
        end


    end % protected methods block
        
    %===========================================================================
    methods(Hidden, Access={?hTestImplicitVsExplicitRowTimes, ...
                            ?matlabtest.datatypes.constraints.TimetableComparator, ...
                            ?matlab.internal.coder.timetable})
        function tf = isImplicitRegular(tt)
            tf = isa(tt.rowDim,'matlab.internal.tabular.private.implicitRegularRowTimesDim');
        end
        
        function tf = isSpecifiedAsRate(tt)
            tf = tt.rowDim.isSpecifiedAsRate();
        end
    end

    %===========================================================================
    methods(Access='protected')
        function [t, t_idx] = getTemplateForConcatenation(catDim,varargin)
            %

            % GETTEMPLATEFORCONCATENATION Get the output template for timetable
            % concatenation that has to correct class and the correct type for
            % the dim objects.

            % Since timetable is superior to tables and inferior to eventtable,
            % if we get dispatched here, then the inputs must only contain
            % timetables, tables and cell arrays. Hence the output type will
            % always be timetable. Go through the list of inputs and select the
            % first non-0x0 timetable as the template.

            if ~isa(varargin{1},'timetable')
                % Tables and cell arrays can be concatenated onto a timetable, but not
                % vice-versa. Even a leading 0x0 table cannot be followed by a timetable.
                throwTableAndTimetableCatError(catDim,iscell(varargin{1}));
            end
            
            t = [];
            t_idx = 0;
            t_is0x0 = true;
            t_uninitialized = true;
            numNon0x0Timetables = 0;
            i = 1;
            % Go through the inputs until we find two non-0x0 timetables.
            while i < nargin && numNon0x0Timetables < 2
                b = varargin{i};
                if isa(b,'timetable')
                    b_is0x0 = sum(size(b)) == 0;
                    numNon0x0Timetables = numNon0x0Timetables + ~b_is0x0;
                    if t_uninitialized ...
                        || (t_is0x0 && ~b_is0x0)
                        % Use b as the template if either the template was
                        % uninitialized or if it was initialized from a 0x0
                        % timetable and b is a non-0x0 timetable.
                        t = b;
                        t_idx = i;
                        t_is0x0 = b_is0x0;
                        t_uninitialized = false;
                    end
                elseif isa(b,'table')
                    % table inputs never impact template selection. However, if
                    % the template was initialized from a 0x0 timetable, then
                    % that might result in an error for certain cases.
                    if ~t_uninitialized && t_is0x0
                        if catDim == 1 && size(b,2) ~= 0
                            % Vertcating 0x0 timetable with 0xN tables is not allowed
                            error(message('MATLAB:table:vertcat:Timetable0x0AndTable'));
                        elseif catDim == 2 && size(b,1) ~= 0
                            % Horzcating 0x0 timetable with Mx0 tables is not allowed
                            error(message('MATLAB:table:horzcat:Timetable0x0AndTable'));
                        end
                    end
                end
                i = i + 1;
            end

            if catDim == 1 && numNon0x0Timetables > 1 && isImplicitRegular(t)
                % If we are vertcating two (or more) non-0x0 timetables, then
                % the output should always be explicit. So update the rowDim if
                % current template has an implicit one.
                t.rowDim = matlab.internal.tabular.private.explicitRowTimesDim(t.rowDim.length,t.rowDim.labels);
            end
        end
    end
    
    %===========================================================================    
    methods(Hidden, Static)
        function name = matlabCodegenRedirect(~)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            % Use the implementation in the class below when generating
            % code.
            name = 'matlab.internal.coder.timetable';
        end
    end
    
    %===========================================================================
    %%%% PERSISTENCE BLOCK ensures correct save/load across releases %%%%%%
    %%%% Properties and methods in this block maintain the exact class %%%%
    %%%% schema required for TIMETABLE to persist through MATLAB releases %    
    properties(Constant, Access='protected')
        % Version of this timetable serialization and deserialization
        % format. This is used for managing forward compatibility. Value is
        % saved in 'versionSavedFrom' when an instance is serialized.
        %
        %   2.0 : 16b. first shipping version
        %
        %   3.0 : 17a. added varDescriptions and varUnits fields to preserve
        %              VariableDescriptions and VariableUnits properties.
        % 
        %   3.1 : 17b. added varContinuity to preserve VariableContinuity property.
        %
        %   3.2 : 18a. added serialized field 'incompatibilityMsg' to support 
        %              customizable 'kill-switch' warning message. The field
        %              is only consumed in loadobj() and does not translate
        %              into any timetable property.
        %
        %   4.0 : 18b. added support for optimized regular timetables. rowTimes
        %              field may now contain either a vector of row times or be
        %              a struct with origin/stepSize/sampleRate/specifiedAsRate
        %              fields. Earlier releases construct from origin/stepSize.
        %
        %              added 'CustomProps' and 'VariableCustomProps' via
        %              tabular/saveobj to preserve per-table and per-variable
        %              custom properties
        %
        %   5.0 : 19b. allow variable names in timetables to include arbitrary
        %              characters. They no longer must be valid MATLAB identifiers.
        %
        %   6.0 : 23a. added support for Events.
        %   7.0 : 25a. increase namelengthmax from 63 to 2048.

        version = 7.0;
    end
    
    methods(Hidden)
        tt_serialized = saveobj(tt);
    end
    
    methods(Hidden, Static)
        tt = loadobj(tt_serialized);
    end
    %===========================================================================
end

%-------------------------------------------------------------------------------
function names = dfltTimetableDimNames()
names = { getString(message('MATLAB:timetable:uistrings:DfltRowDimName')) ...
          getString(message('MATLAB:timetable:uistrings:DfltVarDimName')) };
end

%-----------------------------------------------------------------------
function throwTableAndTimetableCatError(catDim,firstArgWasCell)
if catDim == 1
    catType = 'vertcat';
else
    catType = 'horzcat';
end
if firstArgWasCell
    error(message(['MATLAB:table:' catType ':CellArrayAndTimetable']));
else % the original input was a table
    error(message(['MATLAB:table:' catType ':TableAndTimetable']));
end
end
