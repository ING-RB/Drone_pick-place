%TableAdaptor Adaptor class for tabular tall arrays.

% Copyright 2016-2023 The MathWorks, Inc.

classdef TableAdaptor < matlab.bigdata.internal.adaptors.TabularAdaptor

    methods (Access = protected)
        function m = buildMetadataImpl(obj)
            m = matlab.bigdata.internal.adaptors.TableMetadata(obj.TallSize);
        end
        
        function obj = buildDerived(~, varNames, varAdaptors, dimNames, rowAdaptor, newProps)
            if ~isempty(rowAdaptor)
                error(message('MATLAB:bigdata:table:SetRowNamesUnsupported'));
            end
            obj = matlab.bigdata.internal.adaptors.TableAdaptor(...
                varNames, varAdaptors, dimNames, newProps);
        end
        
        function previewData = fabricatePreview(obj)
            previewData = fabricateTabularPreview(obj, obj.VariableNames);
        end
        
        function data = getRowProperty(~, ~)
            data = {}; % This is always in-memory empty right now but will become tall if ever supported
        end
        
        function throwCannotDeleteRowPropertyError(~)
            error(message('MATLAB:bigdata:table:DeleteRowNamesUnsupported'));
        end
        
        function errorIfFirstSubSelectingRowsNotSupported(~,firstSub)
            if ~matlab.bigdata.internal.util.isColonSubscript(firstSub)
                if (ischar(firstSub) || iscellstr(firstSub) || isstring(firstSub))
                    % Could be an attempt at row-name indexing. Not supported
                    error(message('MATLAB:bigdata:table:SubsrefRowNamesNotSupported'));
                elseif isa(firstSub,'withtol')
                    error(message('MATLAB:withtol:InvalidSubscripter'));
                elseif isa(firstSub,'timerange')
                    error(message('MATLAB:timerange:InvalidSubscripter'));
                elseif isa(firstSub,'vartype')
                    error(message('MATLAB:vartype:InvalidSubscripter'));
                elseif isdatetime(firstSub) || isduration(firstSub)
                    error(message('MATLAB:bigdata:table:InvalidRowSubscript'));
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
            props = fromScalarStruct(matlab.tabular.TallTableProperties, props);
        end
    end
    
    methods
        function obj = TableAdaptor(varargin)
        % TableAdaptor constructor.
        % a = TableAdaptor(previewData) - build from preview data
        % a = TableAdaptor(varNames, varAdaptors) - build from names and adaptors
        % a = TableAdaptor(varNames, varAdaptors, dimNames) - build from names, adaptors
        %                                                     and dimension names
        % a = TableAdaptor(varNames, varAdaptors, dimNames, otherProperties) - internal use
        % constructor to apply 'other' properties.
            narginchk(1,4);

            className   = 'table';
            rowPropName = 'RowNames';
            rowAdaptor  = [];
            
            % Use an empty table to get some defaults
            defaultTable = table();
            defaultDimNames = defaultTable.Properties.DimensionNames;

            if nargin == 1
                % preview data
                previewData = varargin{1};
                
                dimNames = previewData.Properties.DimensionNames;
                varNames = previewData.Properties.VariableNames;
                varAdaptors = cellfun( ...
                    @(vn) matlab.bigdata.internal.adaptors.getAdaptorFromPreview(previewData{[],vn}), ...
                    varNames, 'UniformOutput', false);

                % Copy 'Properties' from the preview data
                otherProps  = previewData.Properties;
            else
                [varNames, varAdaptors] = deal(varargin{1:2});
                dimNames = defaultDimNames;
                otherProps = defaultTable.Properties;
                if nargin == 3
                    dimNames = varargin{3};
                elseif nargin == 4
                    [dimNames, otherProps] = deal(varargin{3:4});
                end
            end

            obj@matlab.bigdata.internal.adaptors.TabularAdaptor(...
                className, defaultDimNames, dimNames, varNames, varAdaptors, ...
                rowPropName, rowAdaptor, otherProps);
        end
    end

    methods (Access = protected)
        % Build a sample of the underlying data.
        function sample = buildSampleImpl(obj, defaultType, sz, preferSquareEmpty)
            fcn = @(rowNames, varargin) table(varargin{:}, 'RowNames', rowNames);
            sample = buildTabularSampleImpl(obj, fcn, defaultType, sz, preferSquareEmpty);
        end
                
        function out = subsasgnRowProperty(adap, pa, ~, b)
            % Assign ROWNAMES. Actual values are not supported, but we allow {} and tall({}).
            bAdap = matlab.bigdata.internal.adaptors.getAdaptor(b);
            if bAdap.Class=="cell" && isequal(bAdap.Size, [0 0])
                % Nothing to do. Just build the output from the input.
                out = tall(pa, adap);
                return
            end
            
            % If non-tall is specified, throw the standard MATLAB error
            if ~istall(b)
                error(message('MATLAB:table:InvalidRowNames'));
            end
            
            % All other cases are unsupported
            error(message('MATLAB:bigdata:table:SetRowNamesUnsupported'));
        end
    end

    methods (Static, Hidden)
        function nonSupportedProps = listNonSupportedProperties()
            supportedProps = string(properties(matlab.tabular.TallTableProperties));
            allProps = string(properties(matlab.tabular.TableProperties));
            nonSupportedProps = setdiff(allProps, supportedProps);
        end
    end
end

