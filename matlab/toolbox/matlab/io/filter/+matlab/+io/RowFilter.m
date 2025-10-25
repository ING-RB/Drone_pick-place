classdef  (InferiorClasses = {?datetime, ?duration, ?categorical}) ...
        RowFilter < matlab.io.internal.AbstractRowFilter & ...
        matlab.internal.tabular.private.subscripter & ...
        matlab.mixin.CustomCompactDisplayProvider
%ROWFILTER   Express filtering operations on a table or timetable.
%
%   A matlab.io.RowFilter instance is returned by all invocations of the rowfilter function.
%
%   Use the rowfilter function to create a matlab.io.RowFilter object for
%   filtering rows in a table or timetable.
%
%   See also: ROWFILTER, PARQUETREAD, PARQUETDATASTORE, PARQUETINFO, PARQUETWRITE.

%   Copyright 2022 The MathWorks, Inc.
properties(Constant, Access='protected')
    version = 1.0;
end
    methods
        function obj = RowFilter(VariableNames)

            import matlab.io.internal.filter.*;
            import matlab.io.internal.filter.properties.*;

            if isa(VariableNames, "matlab.io.datastore.ParquetDatastore")
                VariableNames = VariableNames.SelectedVariableNames;

            elseif isa(VariableNames, "matlab.io.parquet.ParquetInfo")
                VariableNames = VariableNames.VariableNames;

            elseif isa(VariableNames, "tabular")
                rowDimName = [];
                if isa(VariableNames,"timetable")
                    % Include RowTimes in your rowfilter namespace for
                    % timetables.
                    rowDimName = VariableNames.Properties.DimensionNames(1);
                end
                VariableNames = [rowDimName VariableNames.Properties.VariableNames];

            elseif isa(VariableNames, "missing") && isscalar(VariableNames)
                % Easier way to construct a completely empty rowfilter.
                VariableNames = string.empty(0, 1);

            elseif isa(VariableNames, "matlab.io.datastore.DatabaseDatastore")
                % DatabaseDatastore supports filtering on all variable names, not just
                % the selected ones.
                VariableNames = VariableNames.VariableNames;

            end

            try
                if ~isstring(VariableNames) && ~ischar(VariableNames) && ~iscellstr(VariableNames)
                    error(message("MATLAB:io:filter:filter:InvalidRowFilterInput"));
                end

                VariableNames = validateVariableNamesInput(VariableNames);

                % Set the actual RowFilter object from the properties.
                underlyingFilter = MissingRowFilter(MissingRowFilterProperties(VariableNames));
                obj.Properties = ComposedRowFilterProperties(underlyingFilter);
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end
    end
    
     methods(Access={?withtol, ?timerange, ?vartype, ?matlab.io.RowFilter, ?matlab.internal.tabular.private.tabularDimension, ?tabular})
        % The getSubscripts method is called by table subscripting to find the row indices
        % of the conditions specified by the RowFilter.
        function subs = getSubscripts(obj,t,operatingDim)
            if ~(isa(t,'tabular') && matches(operatingDim,'rowDim'))
                error(message("MATLAB:io:filter:filter:InvalidSubscripter"));
            end
            subs = filterIndices(obj,t);
        end
     end

    % Forward to underlying matlab.io.internal.AbstractRowFilter subclasses.
    methods (Hidden)
        function tf = filterIndices(obj, T)
            tf = filterIndices(obj.Properties.UnderlyingFilter, T);
        end

        function obj = traverse(obj, fcn)
            obj.Properties.UnderlyingFilter = traverse(obj.Properties.UnderlyingFilter, fcn);
        end

        function variableNames = constrainedVariableNames(obj)
            variableNames = constrainedVariableNames(obj.Properties.UnderlyingFilter);
        end

        function props = properties(obj)
            props = properties(obj.Properties.UnderlyingFilter);
        end

        function [T, idx] = filter(obj, T)
            [T, idx] = filter(obj.Properties.UnderlyingFilter, T);
        end

        function props = getUnderlyingProperties(obj)
            % Forward to the Properties property on the underlying filter.
            props = getProperties(obj.Properties.UnderlyingFilter);
        end

        function obj = setUnderlyingProperties(obj, props)
            arguments
                obj   (1, 1) matlab.io.RowFilter
                props (1, 1) matlab.io.internal.filter.properties.Properties
            end

            obj.Properties.UnderlyingFilter = setProperties(obj.Properties.UnderlyingFilter, props);
        end

        %--------------- Relational Operator overloads --------------------
        function obj = lt(lhs, rhs)
            try
                obj = applyOperation(lhs, rhs, @lt);
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end

        function obj = le(lhs, rhs)
            try
                obj = applyOperation(lhs, rhs, @le);
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end

        function obj = gt(lhs, rhs)
            try
                obj = applyOperation(lhs, rhs, @gt);
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end

        function obj = ge(lhs, rhs)
            try
                obj = applyOperation(lhs, rhs, @ge);
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end

        function obj = eq(lhs, rhs)
            
            try
                obj = applyOperation(lhs, rhs, @eq);
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end

        function obj = ne(lhs, rhs)
            try
                obj = applyOperation(lhs, rhs, @ne);
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end

        function obj = and(lhs, rhs)
            try
                obj =  applyOperation(lhs,rhs,@and);
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end

        function obj = or(lhs, rhs)
            try
                obj = applyOperation(lhs, rhs, @or);
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end

        function obj = not(input)
            try
                obj = applyOperation(input, @not);
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end
    end

    methods (Static, Hidden)
        function rf = loadobj(S)
            import matlab.io.internal.filter.util.*;

            loadobjCommon(S);
            rf = matlab.io.RowFilter(missing);
            rf.Properties = S.Properties;
        end
    end

    methods (Hidden)
        % Scalar object display methods.
        function s = formatDisplayHeader(obj, classname)
            % Forward to the underlying filter, but replace the classname
            % with the name of this class.
            s = formatDisplayHeader(obj.Properties.UnderlyingFilter, classname);
        end

        function s = formatDisplayBody(obj)
            s = formatDisplayBody(obj.Properties.UnderlyingFilter);
        end

        function rep = compactRepresentationForSingleLine(obj,displayConfiguration,width)
            % Display the full representation of the object in cells and structs
            % Hidden method to dispatch to compactRepresentationForSingleLine
            %   for matlab.mixin.CustomCompactDisplayProvider
            rowFilterRepresentation = formatDisplayBody(obj);

            % Display dimensions and class name if rowFilterRepresentation is an empty string
            if isempty(rowFilterRepresentation)
                rep = matlab.display.DimensionsAndClassNameRepresentation(obj, displayConfiguration, UseSimpleName=true);
               return;
            end

            rep = widthConstrainedDataRepresentation(obj,displayConfiguration,width,...
                StringArray=rowFilterRepresentation);
        end

        function rep = compactRepresentationForColumn(obj,displayConfiguration,width)
            % Adding this to override public method to make this hidden in rowfilter
            rep = compactRepresentationForColumn@matlab.mixin.CustomCompactDisplayProvider(obj,displayConfiguration,width);
        end
    end

    methods (Access = protected)
        function rf = cloneEmptyFilterOutput(lhs,rhs)
            rf = matlab.io.RowFilter(missing);
        end
        
        function rf = applyOperation(lhs,rhs,op)
            % Creates a new matlab.io.RowFilter by setting the UnderlyingFilter
            % and Properties properties.
             import matlab.io.internal.filter.properties.ComposedRowFilterProperties;

             % Construct a new matlab.io.RowFilter
             rf = cloneEmptyFilterOutput(lhs,rhs);

             [lhs, rhs] = unboxFilters(lhs, rhs);
             
             if nargin < 3
                op = rhs;
                f = op(lhs);
             else
                f = op(lhs,rhs);
             end

             % Set the input filter as the underlying filter.
             rf.Properties = ComposedRowFilterProperties(f);
        end

        function varargout = unboxFilters(varargin)
            % Get the underlying filter out of the relational operator arguments.

            varargout = varargin;

            for index = 1:nargin
                arg = varargin{index};

                if isa(arg, "matlab.io.RowFilter")
                    varargout{index} = arg.Properties.UnderlyingFilter;
                end
            end
        end

        function obj = dotReference(input, indexingOperation)
            try
                % Use the "forwarding syntax" to make sure that nested
                % indexing is correctly chained.
                % It all errors anyway this release, but could avoid a
                % future bug.
                obj = applyOperation(input,indexingOperation,@dotReference);
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end
    end

end

function variableNames = validateVariableNamesInput(variableNames)
    arguments
        variableNames (1, :) string {mustBeNonmissing}
    end

    % Just remove duplicates from the input.
    variableNames = unique(variableNames, 'stable');
end

