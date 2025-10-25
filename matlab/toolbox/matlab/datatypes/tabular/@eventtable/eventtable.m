classdef (InferiorClasses={?timetable,?table}) eventtable < timetable & matlab.internal.datatypes.saveLoadCompatibilityExtension
%

%   Copyright 2022-2024 The MathWorks, Inc.

    properties(Constant)
        defaultLabelsVarName = 'EventLabels';
        defaultLengthsVarName = 'EventLengths';
        defaultEndsVarName = 'EventEnds';
    end

    methods
        function obj = eventtable(times,nvPairs)
            arguments
                times = []
                nvPairs.EventLabels
                nvPairs.EventLabelsVariable
                nvPairs.EventLengths
                nvPairs.EventLengthsVariable
                nvPairs.EventEnds
                nvPairs.EventEndsVariable
            end

            if nargin == 0 && isempty(fields(nvPairs))
                % Convert the varNamesDim to varNamesWithEventsDim and return.
                obj.varDim  = matlab.internal.tabular.private.varNamesWithEventsDim(obj.varDim);
                return
            end
            
            suppliedLengths = false;
            suppliedLabels = false;
            suppliedEnds = false;

            if istimetable(times)
                % For timetable inputs, if we are selecting an existing
                % variable as one of the event vars, then simply keep track of
                % the name so that we can tag it later. If we are given raw
                % values, then add them to the timetable as new variables with
                % default names (also fix the default names if they conflict with
                % an existing variable name/dim name in the input timetable).
                tt = times;
                tt.rowDim = tt.rowDim.setTimeEvents([]); % clear any attached events before proceeding.
                nrows = tt.rowDim.length;
                
                % Event Labels
                if isfield(nvPairs,'EventLabelsVariable')
                    if isfield(nvPairs,'EventLabels')
                        % Specifying both raw values and a variable is not allowed.
                        error(message("MATLAB:eventtable:BothLabelsandLabelsVariable"));
                    end
                    suppliedLabels = true;
                    labelsVar = nvPairs.EventLabelsVariable;
                elseif isfield(nvPairs,'EventLabels')
                    suppliedLabels = true;
                    tt = addVarLenient(tt,obj.defaultLabelsVarName,conformEventArg(nvPairs.EventLabels,nrows,"EventLabels"));
                    labelsVar = tt.varDim.length;
                end

                % Event Lengths
                if isfield(nvPairs,'EventLengthsVariable')
                    if isfield(nvPairs,'EventLengths')
                        % Specifying both raw values and a variable is not allowed.
                        error(message("MATLAB:eventtable:BothLengthsandLengthsVariable"));
                    end
                    suppliedLengths = true;
                    lengthsVar = nvPairs.EventLengthsVariable;
                elseif isfield(nvPairs,'EventLengths')
                    suppliedLengths = true;
                    tt = addVarLenient(tt,obj.defaultLengthsVarName,conformEventArg(nvPairs.EventLengths,nrows,"EventLengths"));
                    lengthsVar = tt.varDim.length;
                end
                
                % Event Ends
                if isfield(nvPairs,'EventEndsVariable')
                    if isfield(nvPairs,'EventEnds')
                        % Specifying both raw values and a variable is not allowed.
                        error(message("MATLAB:eventtable:BothEndsandEndsVariable"));
                    end
                    suppliedEnds = true;
                    endsVar = nvPairs.EventEndsVariable;
                elseif isfield(nvPairs,'EventEnds')
                    suppliedEnds = true;
                    tt = addVarLenient(tt,obj.defaultEndsVarName,conformEventArg(nvPairs.EventEnds,nrows,"EventEnds"));
                    endsVar = tt.varDim.length;
                end

            elseif isvector(times) && (isduration(times) || isdatetime(times))
                % For raw datetime or duration inputs, create a timetable using the
                % times and the event vars (if supplied).
                vars = {}; % stores the data of all event vars
                varNames = {}; % stores the names of all eventvars
                nrows = numel(times);

                if ~isfield(nvPairs,'EventLabels') && ~isempty(times)
                    nvPairs.EventLabels = "Event " + (1:nrows)'; % no localization
                end


                % Event Labels
                if isfield(nvPairs,'EventLabelsVariable')
                    error(message("MATLAB:eventtable:FirstInputMustBeTimetable","EventLabelsVariable"));
                elseif isfield(nvPairs,'EventLabels')
                    suppliedLabels = true;
                    vars = {conformEventArg(nvPairs.EventLabels,nrows,"EventLabels")};
                    varNames = {obj.defaultLabelsVarName};
                    labelsVar = {obj.defaultLabelsVarName};
                end

                % Event Lengths
                if isfield(nvPairs,'EventLengthsVariable')
                    error(message("MATLAB:eventtable:FirstInputMustBeTimetable","EventLengthsVariable"));
                elseif isfield(nvPairs,'EventLengths')
                    suppliedLengths = true;
                    vars{end+1} = conformEventArg(nvPairs.EventLengths,nrows,"EventLengths");
                    varNames{end+1} = obj.defaultLengthsVarName;
                    lengthsVar = {obj.defaultLengthsVarName};
                end
                
                % Event Ends
                if isfield(nvPairs,'EventEndsVariable') 
                    error(message("MATLAB:eventtable:FirstInputMustBeTimetable","EventEndsVariable"))
                elseif isfield(nvPairs,'EventEnds')
                    suppliedEnds = true;
                    vars{end+1} = conformEventArg(nvPairs.EventEnds,nrows,"EventEnds");
                    varNames{end+1} = obj.defaultEndsVarName;
                    endsVar = {obj.defaultEndsVarName};
                end

                % Create a timetable using the variables and variable names we
                % collected above.
                tt = timetable(vars{:},RowTimes=times,VariableNames=varNames);
            else
                % First input must be a timetable or a times vector.
                error(message("MATLAB:eventtable:InvalidFirstInput"));
            end

            if suppliedLengths && suppliedEnds
                % Specifying both EventLengths and EventEnds is not allowed.
                error(message("MATLAB:eventtable:BothLengthsandEnds"));
            end

            % Convert the timetable into an eventtable.
            obj = obj.initFromTimetable(tt);
           
            % Set event properties.
            if suppliedLabels,  obj.varDim = obj.varDim.setEventLabelsVariable(labelsVar,obj.data);                                 end
            if suppliedLengths, obj.varDim = obj.varDim.setEventLengthsVariable(lengthsVar,obj.data, class(obj.rowDim.startTime));  end
            if suppliedEnds,    obj.varDim = obj.varDim.setEventEndsVariable(endsVar,obj.data, obj.rowDim.startTime);               end
        end
    end

    %===========================================================================
    methods(Access = 'protected')
        t = primitiveHorzcat(t,varargin)
        
        function p = emptyPropertiesObj(~)
            persistent props

            if isnumeric(props)
                props = matlab.tabular.EventtableProperties;
            end
            p = props;
        end

        function propNames = propertyNames(t)
            persistent arrayPropsMod

            if isnumeric(arrayPropsMod)
                % Need to manage CustomProperties which are stored in two different
                % places.
                arrayPropsMod = tabular.arrayPropsDflts;
                arrayPropsMod = rmfield(arrayPropsMod, 'TableCustomProperties');
                arrayPropsMod = fieldnames(arrayPropsMod);
                arrayPropsMod = [arrayPropsMod; ...
                    t.metaDim.propertyNames; ...
                    t.varDim.propertyNames; ...
                    t.rowDim.propertyNames; ...
                    'CustomProperties'];
                arrayPropsMod(matches(arrayPropsMod, 'Events')) = [];
            end
            propNames = arrayPropsMod;
        end

        function h = getDisplayHeader(t,~)
            % GETHEADER is called by display method to print the header
            % specific to the tabular subclass. Prints tagged variable
            % information in eventtable header.
            import matlab.internal.display.lineSpacingCharacter
            import matlab.internal.display.truncateLine

            displayNewline = "\n"+lineSpacingCharacter;
            h = t.getDisplayHeader@tabular() + displayNewline;

            labelVarName = t.varDim.eventLabelsVariable;
            if ~t.varDim.hasEventLabels
                labelVarName = getString(message('MATLAB:eventtable:UILabelsVarUnset'));
            end
            h = h + "  " + getString(message('MATLAB:eventtable:UILabelsVar')) + " " + truncateLine(labelVarName)+newline;

            lengthVarName = t.varDim.eventLengthsVariable;
            endVarName = t.varDim.eventEndsVariable;
            if ~(t.varDim.hasEventLengths || t.varDim.hasEventEnds)
                h = h + "  " + getString(message('MATLAB:eventtable:UILengthsVar')) + " " + getString(message('MATLAB:eventtable:UILengthsVarInstant'));
            end

            if t.varDim.hasEventLengths
                h = h + "  " + getString(message('MATLAB:eventtable:UILengthsVar')) + " " + truncateLine(lengthVarName);
            elseif t.varDim.hasEventEnds
                h = h + "  " + getString(message('MATLAB:eventtable:UIEndsVar')) + " " + truncateLine(endVarName);
            end
        end

        function b = cloneAsEmpty(a)
            b = eventtable();
            b.rowDim = a.rowDim.shortenTo(0);
        end
        
        function [template,rowOrder,varOrder] = getTemplateForBinaryMath(A,B,fun,unitsHelper)
            % GETTEMPLATEFORBINARYMATH Get the output template for eventtable
            % binary math operations that has the correct class and the correct type for
            % the dim objects.

            % Since eventtable is superior to tables and timetables, if we get
            % dispatched here, then the inputs must contain either tables
            % or timetables and eventtables. Hence the output type will always be
            % eventtable. 
            % 
            % The template selection rules for eventtable are the same as
            % timetable so simply call tabular's getTemplateForBinaryMath.
            % If the selected template is an eventtable then pass it
            % through, and if it is a timetable then convert it to an
            % eventtable before sending it through.
            [template,rowOrder,varOrder] = getTemplateForBinaryMath@tabular(A,B,fun,unitsHelper);
            
            % If an eventtable is the first input to the math operation, no
            % further work needs to be done, and the template will be an
            % eventtable. If a timetable is the first input to the math
            % operation, we need to ensure the output is an eventtable.
            if ~isa(template,'eventtable')
                template = eventtable.initFromTimetable(template);
            end
            
            % Binary math operations with two eventtables do not need to
            % enter this branch. A binary operation with a table as the
            % first input and an eventtable as the second input needs the
            % right varDim. A binary operation with a timetable as the
            % first input and an eventtable as the second input already has
            % the correct varDim from initFromTimetable above, so only
            % event properties need to be copied over.
            if ~isa(A,'eventtable') && isa(B,'eventtable')
                if ~isa(A,'timetable')
                    % Make sure the eventtable has the correct varDim.
                    % This is only reached when a table is the first input to
                    % the math operation, such as t + et.
                    template.varDim = matlab.internal.tabular.private.varNamesWithEventsDim(template.varDim);
                end

                % Copy over the tagged event properties from the second
                % input, after ensuring the output will be an eventtable.
                template.varDim = copyEventProps(template.varDim,B.varDim);
            end

            % Relational operations will always fail when the event table
            % has event lengths or event ends because neither tagged
            % variable can be logical. In that case, throw a more
            % descriptive error message.
            if (template.varDim.hasEventLengths || template.varDim.hasEventEnds) && isRelationalOperator(fun)
                error(message('MATLAB:eventtable:RelationalOperation',func2str(fun)));
            end

            function tf = isRelationalOperator(fun)
                tf = isequal(fun,@and) || isequal(fun,@or) || isequal(fun,@xor) || ...
                     isequal(fun,@eq)  || isequal(fun,@ne) || isequal(fun,@ge)  || ...
                     isequal(fun,@gt)  || isequal(fun,@le) || isequal(fun,@lt);
            end
        end

        function [t, t_idx] = getTemplateForConcatenation(catDim,varargin)
            % GETTEMPLATEFORCONCATENATION Get the output template for eventtable
            % concatenation that has to correct class and the correct type for
            % the dim objects.

            % Since eventtable is superior to tables and timetables, if we get
            % dispatched here, then the inputs must contain tables, timetables,
            % eventtables and cell arrays. Hence the output type will always be
            % eventtable. The template selection rules for eventtable is the
            % same as timetable so simply call timetable's
            % getTemplateForConcatenation. If the selected template is an
            % eventtable then pass it through and if it is a timetable then
            % convert it to an eventtable before sending it through.

            [t, t_idx] = getTemplateForConcatenation@timetable(catDim,varargin{:});
            if ~isa(t,'eventtable')
                % Convert a timetable template to an eventtable.
                t = eventtable.initFromTimetable(t);
                if catDim == 1 % vertcat
                    % If we are getting the template for vertcat, then we must
                    % set the Event*Variable properties to the correct values.
                    % For vertcat all eventtables must have these properties set
                    % to the same value, so we can simply pick those from the
                    % first non-empty eventtable in the list without doing any
                    % validation. It is possible that these values might be
                    % incorrect, because 1. The timetable from which the
                    % template was created does not have the variable or 2. The
                    % variable has incorrect data type in the template or 3. All
                    % inputs do not have the same values for these properties.
                    % We do not have to worry about these cases here, let them
                    % pass through and the vertcat code will throw a more
                    % specific and helpful error for each of these scenarios.
                    for i = 1:(nargin-1)
                        b = varargin{i};
                        if isa(b,'eventtable') && sum(size(b)) ~= 0
                            t.varDim = copyEventProps(t.varDim,b.varDim);
                            break;
                        end
                    end
                end
            end
        end

        function validateAcrossVars(et,NameValueArgs)
            % VALIDATEACROSSVARS Handles validations that check for
            % compatability across different variables and meta data in the
            % tabular. For eventtables it validates that the tagged event
            % variables have the appropriate type and size.

            arguments
                et
                NameValueArgs.FunName
            end

            % Event Labels
            if et.varDim.hasEventLabels
                validateEventLabels(et,NameValueArgs);
            end

            % Event Lengths or Event Ends
            if et.varDim.hasEventLengths
                validateEventLengths(et,NameValueArgs);
            elseif et.varDim.hasEventEnds
                validateEventEnds(et,NameValueArgs);
            end

            function validateEventLabels(et, NameValueArgs)
                try
                    matlab.internal.tabular.validateEventLabels(et.data{et.varDim.eventLabelsIdx},"eventtable");
                catch ME
                    if isfield(NameValueArgs,"FunName")
                        varName = et.varDim.labels{et.varDim.eventLabelsIdx};
                        msg = message("MATLAB:eventtable:InvalidOutputLabels",NameValueArgs.FunName,varName);
                        ME = MException(msg).addCause(ME);
                    end
                    throw(ME);
                end
            end

            function validateEventLengths(et, NameValueArgs)
                try
                    matlab.internal.tabular.validateEventLengths(et.data{et.varDim.eventLengthsIdx},class(et.rowDim.startTime));
                catch ME
                    if isfield(NameValueArgs,"FunName")
                        varName = et.varDim.labels{et.varDim.eventLengthsIdx};
                        msg = message("MATLAB:eventtable:InvalidOutputLengths",NameValueArgs.FunName,varName);
                        ME = MException(msg).addCause(ME);
                    end
                    throw(ME);
                end
            end

            function validateEventEnds(et, NameValueArgs)
                try
                    matlab.internal.tabular.validateEventEnds(et.data{et.varDim.eventEndsIdx},et.rowDim.startTime);
                catch ME
                    if isfield(NameValueArgs,"FunName")
                        varName = et.varDim.labels{et.varDim.eventEndsIdx};
                        msg = message("MATLAB:eventtable:InvalidOutputEnds",NameValueArgs.FunName,varName);
                        ME = MException(msg).addCause(ME);
                    end
                    throw(ME);
                end
            end
        end
    end

    %===========================================================================
    methods (Hidden, Access = 'public')
        % This function is for internal use only and will change in a future release.
        % Do not use this function.
        et = mergeevents(et1,et2)
        
        function [tf,endOrLengthVar] = hasInstantEvents(et)
             % This function is for internal use only and will change in a future release.
             % Do not use this function.
             
             % Determine if a given eventtable represents instantaneous events
             % or time period events. Also return the name of the ends or
             % lengths variable (whichever is present) as the second argument.
             tf = false;
             endOrLengthVar = [];
             if ~isnumeric(et.varDim.eventLengthsVariable)
                 endOrLengthVar = et.varDim.eventLengthsVariable;
             elseif ~isnumeric(et.varDim.eventEndsVariable)
                 endOrLengthVar = et.varDim.eventEndsVariable;
             else
                 tf = true;
             end     
        end

        function [eventTimes,eventEndTimes] = eventIntervalTimes(et,eventIndices)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.

            if nargin < 2
                eventIndices = ':';
            end
            
            % Return the start and end times of interval events in an eventtable. For
            % instantaneous events, return the times and [].
            eventTimes = et.rowDim.labels(eventIndices); % t.Properties.RowTimes
            if et.varDim.hasEventLengths
                lengths = et.data{et.varDim.eventLengthsIdx}(eventIndices); % t.(t.Properties.EventLengthsVariable);
                eventEndTimes = eventTimes + lengths;
            elseif et.varDim.hasEventEnds
                eventEndTimes = et.data{et.varDim.eventEndsIdx}(eventIndices); % t.(t.Properties.EventEndsVariable);
            else % neither is set, i.e. instantaneous events
                eventEndTimes = [];
            end
        end

        function tt = convertToTimetable(et)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.

            tt = timetable();
            tt.varDim = matlab.internal.tabular.private.varNamesDim(et.varDim.length,et.varDim.labels);
            tt.varDim = moveProps(tt.varDim,et.varDim,1:tt.varDim.length,1:tt.varDim.length);
            tt.metaDim = et.metaDim;
            tt.rowDim = et.rowDim;
            tt.data = et.data;
            tt.arrayProps = et.arrayProps;
        end
    end

    %===========================================================================
    methods(Hidden, Static)
        function et = empty(varargin)
            et = timetable.empty(varargin{:});
            et = eventtable.initFromTimetable(et);
        end

        function et = createArray(varargin)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            et = tabular.createArrayImpl(@(fillval)eventtable(timetable(fillval,RowTimes=NaT)),varargin{:});
        end
    end

    %===========================================================================   
    methods (Access = 'private', Static)
        function et = initFromTimetable(tt)
            % Initialize an eventtable from a timetable.
            et = eventtable();
            et.varDim = matlab.internal.tabular.private.varNamesWithEventsDim(tt.varDim);
            % Remove timeEvents from tt.rowDim and use that.
            et.rowDim = tt.rowDim.setTimeEvents([]);
            et.metaDim = tt.metaDim;
            et.data = tt.data;
            et.arrayProps = tt.arrayProps;
        end
    end
    
    %===========================================================================
    methods (Access = 'public', Hidden, Static)
        function et = init(rowTimes, vars, eventProperties)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            try
                numEvents = length(rowTimes);
                numVars = length(eventProperties);
                tt = timetable.init(vars,numEvents,rowTimes,numVars,eventProperties);
                et = eventtable.initFromTimetable(tt);
                et.varDim = et.varDim.setEventLabelsVariable("EventLabels",vars);
                if any(eventProperties == "EventLengths")
                    et.varDim = et.varDim.setEventLengthsVariable("EventLengths",vars);
                elseif any(eventProperties == "EventEnds")
                    et.varDim = et.varDim.setEventEndsVariable("EventEnds",vars);
                end
            catch ME
                throwAsCaller(ME);
            end
        end
    end

    %===========================================================================
    %%%% PERSISTENCE BLOCK ensures correct save/load across releases %%%%%%%
    %%%% Properties and methods in this block maintain the exact class %%%%%
    %%%% schema required for EVENTTABLE to persist through MATLAB releases %    
    properties(Constant, Access=protected)
        % Version of this eventtable serialization and deserialization
        % format. This is used for managing forward compatibility. Value is
        % saved in 'versionSavedFrom' when an instance is serialized.
        %
        %   1.0 : 23a. first shipping version
        %   2.0 : 25a. namelengthmax increased from 63 to 2048.
        eventtableVersion = 2.0;
    end

    methods(Hidden)
        et_serialized = saveobj(et);
    end

    methods(Hidden, Static)
        et = loadobj(et_serialized);
    end
    %===========================================================================
end

%-------------------------------------------------------------------------------
function val = conformEventArg(val,nrows,argName)
% Helper function to convert the raw event arguments into valid eventtables
% variables and error if that cannot be done.
    if isscalar(val)
        % Expand out a scalar value to match the number of rows in the eventtable.
        val = repmat(val,nrows,1);
    elseif isvector(val) && (numel(val) == nrows)
        if isrow(val)
            % convert row vector into a column vector
            val = val(:); 
        end
    elseif size(val,1) == nrows
        % It is a non-vector with the correct number of rows, so its a valid
        % variable, however, the tagged variables in an eventtable cannot be
        % non-vectors. So let it pass through and let the tagged var validation
        % functions throw a more specific error.
    else
        % Anything else is an error.
        throwAsCaller(MException(message("MATLAB:eventtable:WrongHeightArg",argName)));
    end
end
