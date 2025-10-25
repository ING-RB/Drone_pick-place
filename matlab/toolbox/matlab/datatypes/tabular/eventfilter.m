classdef (InferiorClasses = {?datetime, ?duration, ?categorical}) ...
        eventfilter < matlab.io.RowFilter & matlab.internal.datatypes.saveLoadCompatibilityExtension
%

%   Copyright 2022-2024 The MathWorks, Inc.

    methods
        function obj = eventfilter(input)
            import matlab.io.internal.filter.*;
            import matlab.io.internal.filter.properties.*;
            import matlab.io.internal.filter.util.makeRelationalOperatorEnum;
    
            obj =  obj@matlab.io.RowFilter(missing);
            if nargin == 0
                % Return a default unconstrained filter with an empty namespace.
                variableNames = string.empty(0, 1);
                underlyingFilter = MissingEventFilter(MissingRowFilterProperties(variableNames));
                obj.Properties = ComposedRowFilterProperties(underlyingFilter);
                return
            end

            if isa(input, "timetable")
                if isa(input,"eventtable")
                    % Cannot create an eventfilter from an eventtable because the
                    % eventtable has no attached events to filter.
                    error(message("MATLAB:eventfilter:EventTableInput"));
                end
                events = input.Properties.Events;
                if isnumeric(events) % [], as in a timetable with no attached eventtable
                    error(message("MATLAB:eventfilter:NoEventsAttached"));
                end

                % Create an unconstrained filter from the eventtable's variables namespace
                % and box it up.
                variableNames = [events.Properties.DimensionNames(1) events.Properties.VariableNames];
                underlyingFilter = MissingEventFilter(MissingRowFilterProperties(variableNames));
                obj.Properties = ComposedRowFilterProperties(underlyingFilter);
            
            else % create an eventfilter from a list of event label values.
                if isrow(input) && ~ischar(input)
                    try
                        % Convert row vectors into column vectors before doing
                        % validation. Leave char row vector alone.
                        input = input(:);
                    catch
                        % If input cannot be converted to a column vector for
                        % some reason (for e.g. input is a table and does not
                        % support linear indexing, etc.) leave it as it is and
                        % validateEventLabels would throw a more helpful error
                        % for this case.
                    end
                end
                % Validate that the input adheres to all the size and type
                % restrictions for event labels.
                matlab.internal.tabular.validateEventLabels(input,"eventfilter"); 
                
                if isempty(input)
                    % validateEventLabels would allow empty values, but creating
                    % an eventfilter with empty labels would be unuseable. So
                    % throw an error if that is the case.
                    throwAsCaller(MException(message(append("MATLAB:eventfilter:InvalidLabelsVariableSize"))));
                elseif ischar(input)
                    % Treat a char row as one value
                    numConstraints = 1;
                    val = input;
                else
                    numConstraints = numel(input);
                    % Start the filter with the first value (or nothing if the value is empty).
                    if numel(input) < 1
                        val = input; % preserve the empty's shape
                    else
                        val = input(1);
                    end
                end

                eventLabelsVariableTag = getString(message("MATLAB:eventfilter:UIStringDispEventLabelsVariable"));
                props = SingleVariableRowFilterProperties(eventLabelsVariableTag,makeRelationalOperatorEnum("=="),val,string.empty(0, 1));
                underlyingFilter = SingleVariableEventFilter(props);

                % OR the remaining event label values into the filter
                for i = 2:numConstraints
                    val = input(i);
                    props = SingleVariableRowFilterProperties(eventLabelsVariableTag,makeRelationalOperatorEnum("=="),val,string.empty(0, 1));
                    underlyingFilter = underlyingFilter | SingleVariableEventFilter(props);
                end

                % Box up the underlying filter.
                obj.Properties = ComposedRowFilterProperties(underlyingFilter);
            end
        end
    end

    methods (Hidden)
        function obj = and(lhs, rhs)
            if ~isequal(class(lhs),class(rhs))
                error(message("MATLAB:eventfilter:InvalidBinaryOperatorInputs"));
            end
            obj = and@matlab.io.RowFilter(lhs,rhs);
        end

        function obj = or(lhs, rhs)
            if ~isequal(class(lhs),class(rhs))
                error(message("MATLAB:eventfilter:InvalidBinaryOperatorInputs"));
            end
            obj = or@matlab.io.RowFilter(lhs,rhs);
        end

        function obj = not(~) %#ok<STOUT>
            % eventfilter does not support the negation operator because it
            % can lead to ambiguous uses.
            error(message("MATLAB:eventfilter:NegationUnsupported"));
        end
    end
   
    methods (Access = protected)
        function ef = cloneEmptyFilterOutput(~, ~)
            %

            % Construct a new eventfilter for the output of an operation.
            ef = eventfilter(missing);
        end
    end

    methods(Access={?withtol, ?timerange, ?vartype, ?matlab.io.RowFilter, ?matlab.internal.tabular.private.tabularDimension, ?tabular})
        % The getSubscripts method is called by table subscripting to find the row indices
        % of the conditions specified by the eventfilter.
        function rowIndices = getSubscripts(obj,tt,operatingDim)
            if ~(isa(tt,'timetable') && matches(operatingDim,'rowDim'))
                error(message("MATLAB:eventfilter:InvalidSubscripter"));
            elseif isa(tt,"eventtable")
                % Cannot use an eventfilter as a subscript into an eventtable because the
                % eventtable has no attached events to filter.
                error(message("MATLAB:eventfilter:EventFilterOnEventTable"));
            elseif isnumeric(tt.rowDim.timeEvents) % [], as in a timetable with no attached eventtable
                error(message("MATLAB:eventfilter:NoEventsForSubscripting"));
            end

            % Use the eventfilter to find rows in the timetable's eventtable that match
            % the condition.
            rowIndices = filterIndices(obj,tt);
        end
    end

    methods (Hidden)
        function S = saveobj(ef)
            % Store save-load metadata.
            S = saveobj@matlab.io.RowFilter(ef);
            S = ef.setCompatibleVersionExtensionLimit(S, ...
                ClassName=class(ef), ...
                VersionNum=ef.eventfilterVersion, ...
                MinCompatibleVersion=1.0);
        end 
    end

    methods (Static, Hidden)
        function ef = loadobj(S)
            import matlab.io.internal.filter.util.*;

            % Return an empty instance if current version is below the
            % minimum compatible version of the serialized object.
            ef = eventfilter(missing);
            if ef.isIncompatibleVersionExtension(S, ...
                    ClassName=class(ef), ...
                    VersionNum=ef.eventfilterVersion, ...
                    WarnMsgId="MATLAB:eventtable:IncompatibleEventFilterLoad")
                return
            end

            loadobjCommon(S);
            ef = eventfilter(missing);
            ef.Properties = S.Properties;
        end
    end

    %===========================================================================
    %%%% PERSISTENCE BLOCK ensures correct save/load across releases %%%%%%%%
    %%%% Properties and methods in this block maintain the exact class %%%%%%
    %%%% schema required for EVENTFILTER to persist through MATLAB releases %    
    properties (Constant, Access=protected)
        % Version of this eventfilter serialization and deserialization
        % format. This is used for managing forward compatibility. Value
        % is saved in 'versionSavedFrom' when an instance is serialized.
        %
        %   1.0 : 23a. first shipping version

        eventfilterVersion = 1.0;
    end
end
