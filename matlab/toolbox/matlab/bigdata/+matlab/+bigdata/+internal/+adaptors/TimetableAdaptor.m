%TimetableAdaptor Adaptor class for tabular tall arrays.

% Copyright 2016-2022 The MathWorks, Inc.

classdef TimetableAdaptor < matlab.bigdata.internal.adaptors.TabularAdaptor
    methods (Access = protected)
        function m = buildMetadataImpl(obj)
        % SUMMARY is not currently supported for tall timetable, so simply gather
        % generic metadata.
            m = matlab.bigdata.internal.adaptors.GenericArrayMetadata(obj.TallSize);
        end

        function obj = buildDerived(~, varNames, varAdaptors, dimNames, rowAdaptor, newProps)
            if ~ismember(rowAdaptor.Class, {'datetime', 'duration'})
                error(message('MATLAB:timetable:InvalidRowTimes'));
            end
            obj = matlab.bigdata.internal.adaptors.TimetableAdaptor(...
                varNames, varAdaptors, dimNames, rowAdaptor, newProps);
        end

        function previewData = fabricatePreview(obj)
            previewData = fabricateTabularPreview(obj, [obj.DimensionNames{1}, obj.VariableNames]);
        end

        function varargout = getRowProperty(obj, pa)
        % Getting the rowtimes vector
            substr = substruct('.', obj.DimensionNames{1});
            [varargout{1:nargout}] = tall(slicefun(@subsref, pa, substr), obj.RowAdaptor);
        end

        function throwCannotDeleteRowPropertyError(~)
            error(message('MATLAB:timetable:CannotRemoveRowTimes'));
        end
        
        function errorIfFirstSubSelectingRowsNotSupported(~, firstSub)
            if ~matlab.bigdata.internal.util.isColonSubscript(firstSub)
                if isa(firstSub, 'vartype')
                    error(message('MATLAB:vartype:InvalidSubscripter'));
                end
            end
        end
        
        function props = getPropertiesStruct(obj, pa)
            % Return Properties struct
            p = obj.OtherProperties;
            props = struct( ...
                'Description',          {p.Description}, ...
                'UserData',             {p.UserData}, ...
                'DimensionNames',       {obj.DimensionNames}, ...
                'VariableNames',        {obj.VariableNames}, ...
                'VariableDescriptions', {p.VariableDescriptions}, ...
                'VariableUnits',        {p.VariableUnits}, ...
                'VariableContinuity',   {p.VariableContinuity}, ...
                'CustomProperties',     {p.CustomProperties}, ...
                obj.RowPropertyName,    {obj.getRowProperty(pa)});
            props = fromScalarStruct(matlab.tabular.TallTimetableProperties, props);
        end
        
    end

    methods
        function obj = TimetableAdaptor(varargin)
        % Supported Syntaxes:
        % Build from preview data:
        % TimetableAdaptor(previewData)
        %
        % Build with variable names, variable adaptors, dimension names, and adaptor for RowTimes:
        % TimetableAdaptor(varNames, varAdaptors, dimNames, rowtimesAdaptor)
        %
        % As above, but additionally with other elements of 'Properties'.
        % TimetableAdaptor(varNames, varAdaptors, dimNames, rowtimesAdaptor, otherProperties)

            narginchk(1,5);
            className   = 'timetable';
            rowPropName = 'RowTimes';

            % Use an empty table to get some defaults
            defaultTimetable = timetable();
            defaultDimNames = defaultTimetable.Properties.DimensionNames;

            if nargin == 1
                % preview data
                previewData = varargin{1};
                dimNames    = previewData.Properties.DimensionNames;
                rowAdaptor  = matlab.bigdata.internal.adaptors.getAdaptorFromPreview(previewData.(dimNames{1}));
                varNames    = previewData.Properties.VariableNames;
                varAdaptors = cellfun( ...
                    @(vn) matlab.bigdata.internal.adaptors.getAdaptorFromPreview(previewData{[],vn}), ...
                    varNames, 'UniformOutput', false);

                otherProps  = previewData.Properties;
            else
                assert(nargin == 4 || nargin == 5, ...
                    'Assertion failed: TimetableAdaptor expected 4 or 5 inputs.')
                [varNames, varAdaptors, dimNames, rowAdaptor] = deal(varargin{1:4});
                if nargin == 4
                    otherProps = defaultTimetable.Properties;
                else
                    otherProps = varargin{5};
                end
            end
            obj@matlab.bigdata.internal.adaptors.TabularAdaptor(...
                className, defaultDimNames, dimNames, varNames, varAdaptors, ...
                rowPropName, rowAdaptor, otherProps);
        end

        function clz = getDimensionNamesClass(obj)
        % getDimensionNamesClass - get the class of RowTimes.
            clz = obj.RowAdaptor.Class;
        end
    end
    
    methods (Access=protected)
        % Build a sample of the underlying data.
        function sample = buildSampleImpl(obj, defaultType, sz, preferSquareEmpty)
            fcn = @(rowTimes, varargin) timetable(varargin{:}, 'RowTimes', rowTimes);
            sample = buildTabularSampleImpl(obj, fcn, defaultType, sz, preferSquareEmpty);
        end
        
        function out = subsasgnRowProperty(adap, pa, szPa, b)
            % Assign ROWTIMES
            % We simply divert this call to set tt.Time.
            subs = substruct('.', adap.DimensionNames{1});
            out = adap.subsasgnDot(pa, szPa, subs, b);
        end
    end

    methods (Static, Hidden)
        function nonSupportedProps = listNonSupportedProperties()
            supportedProps = string(properties(matlab.tabular.TallTimetableProperties));
            allProps = string(properties(matlab.tabular.TimetableProperties));
            nonSupportedProps = setdiff(allProps, supportedProps);
        end
    end
end
