%TabularAdaptor Base class for TableAdaptor and TimetableAdaptor

% Copyright 2016-2023 The MathWorks, Inc.

classdef TabularAdaptor < matlab.bigdata.internal.adaptors.AbstractAdaptor

    properties (SetAccess = immutable, GetAccess = protected)
        % The name of the "row" property
        % - either 'RowNames' for a table, or 'RowTimes' for a timetable
        RowPropertyName
        % The default dimension names, either {'Row','Variables'} for a
        % table, or {'Time','Variables'} for a timetable.
        DefaultDimensionNames
    end

    properties (SetAccess = private, GetAccess = protected)
        DimensionNames
        VariableNames
        OtherProperties

        VariableAdaptors

        % This might be empty if there is no Row
        RowAdaptor
    end

    properties (Transient)
        % Map of variable name to tall array. Cache these so that repeated extractions
        % of variables from the tall table get precisely the same tall array -
        % complete with metadata if possible. The implementation uses a
        % containers.Map to cache tall arrays. This is a handle type, which
        % allows the cache to function even though the adaptor is a value
        % type. However, this means that we must be careful to build a fresh
        % containers.Map instance when the adaptor is made aware of a
        % modification that invalidates the cache.
        VariableTallArraysCache
    end

    properties (Constant, GetAccess = protected)
        % This is the list of properties that OtherProperties must contain.
        OtherPropertiesFields = { ...
            'Description'; 'UserData'; 'VariableDescriptions'; 'VariableUnits';...
            'VariableContinuity'; 'CustomProperties'};
    end

    methods (Abstract, Access = protected)
        obj = buildDerived(obj, varNames, varAdaptors, dimNames, rowAdaptor, newProps, customVarPropNames);
        data = fabricatePreview(obj);

        % Return the RowNames / RowTimes
        props = getRowProperty(obj, pa);

        % This is called when someone attempts to delete the 'Row' property. This
        % assumes that it is never possible. If we ever support deleting 'Row'
        % for a table, then we'd need to change this.
        throwCannotDeleteRowPropertyError(obj);

        % Throw error if row indexing is not support;
        errorIfFirstSubSelectingRowsNotSupported(obj,firstSub);

        % Set the special row property (RowNames, RowTimes)
        out = subsasgnRowProperty(adap, pa, szPa, b);

        % Get the properties struct
        props = getPropertiesStruct(obj, pa);
    end

    methods (Access = private)
        function obj = copyTallSizeToAllSubAdaptors(obj)
            for idx = 1:numel(obj.VariableAdaptors)
                obj.VariableAdaptors{idx} = copyTallSize(obj.VariableAdaptors{idx}, obj);
            end
            if ~isempty(obj.RowAdaptor)
                obj.RowAdaptor = copyTallSize(obj.RowAdaptor, obj);
            end
        end

        function [varNames, varIdxs] = resolveVarNameSubscript(obj, subscript)
            % Subscript type conversions - resolve certain types up-front.
            if isa(subscript, "matlab.bigdata.internal.util.EndMarker")
                % For table indexing, we must resolve EndMarkers in the second subscript at the
                % client right away.
                szVec = [0, numel(obj.VariableNames)];
                subscript = resolve(subscript, szVec, 2);
            end
            % VarType is specific to indexing (can't be used in other var
            % operations) so deal with it explicitly here.
            if isa(subscript, "vartype")
                subscript = obj.resolveVarTypeSubscript(subscript);
            end

            [varNames, varIdxs] = matlab.bigdata.internal.util.resolveTableVarSubscript(...
                obj.VariableNames, subscript);
        end

        function tf = resolveVarTypeSubscript(obj, subscript)
            % Resolve a VarType subscript into a logical subscript
            % (will throw if any adaptor has unknown type).
            assert(isa(subscript, "vartype"), "resolveVarType requires a VarType");
            % Ignore tables with no variables
            if isempty(obj.VariableAdaptors)
                tf = false(size(obj.VariableAdaptors));
                return;
            end

            adapClasses = cellfun(@(x) string(x.Class), obj.VariableAdaptors);
            if any(strlength(adapClasses)==0)
                % A variable has unknown class. We can't continue.
                error(message("MATLAB:bigdata:table:VartypeUnknownType"));
            end

            % VARTYPE doesn't let us discover the type it is testing except via
            % display, and neither does it provide access to the indices it selected.
            % Instead we can make a preview array, call vartype and then
            % reverse-engineer what it selected, relying on the fact that
            % variable names are guaranteed unique.
            sampleBefore = obj.buildSample("double");
            sampleAfter = sampleBefore(:, subscript);
            tf = ismember(sampleBefore.Properties.VariableNames, sampleAfter.Properties.VariableNames);
        end

        % Resolve a single dot-subscript
        function varName = resolveDotSubscript(obj, subscript, allowMissing)
            % For cases tt.Foo and equivalently tt.('Foo'), we allow the subscript to be
            % only: scalar string, char-vector, and numeric integer scalar.

            % Handle scalar strings by converting to char.
            if isstring(subscript) && isscalar(subscript)
                subscript = char(subscript);
            end

            if ischar(subscript) || ...
                    (isnumeric(subscript) && isscalar(subscript) && round(subscript) == subscript)

                if allowMissing && ischar(subscript)
                    % Missing variables are allowed.
                    varName = subscript;
                elseif allowMissing && isnumeric(subscript)
                    % Numeric integer scalar - must be in range, or one off the end.
                    if subscript <= numel(obj.VariableNames)
                        varName = obj.VariableNames{subscript};
                    elseif subscript == (1 + numel(obj.VariableNames))
                        % Appending a new variable with generated name
                        varName = sprintf('Var%d', subscript);
                        idx     = 1;
                        while ismember(varName, obj.VariableNames)
                            varName = sprintf('Var%d_%d', subscript, idx);
                            idx     = idx + 1;
                        end
                    else
                        % Outside allowed bounds
                        error(message('MATLAB:table:DiscontiguousVars'));
                    end
                elseif matlab.bigdata.internal.util.isColonSubscript(subscript)
                    error(message('MATLAB:table:UnrecognizedVarName', subscript));
                else
                    % Finally, get here to resolve numeric integer scalars or char-vectors against
                    % known variable names, re-use resolveVarNameSubscript.
                    varNames = obj.resolveVarNameSubscript(subscript);
                    assert(isscalar(varNames), ...
                        'Unexpectedly resolved dot-subscript to multiple variables.');
                    varName = varNames{1};
                end
            else
                error(message('MATLAB:table:IllegalVarSubscript'));
            end
        end
    end

    methods (Access = protected)
        function obj = TabularAdaptor(className, defaultDimNames, dimNames, varNames, varAdaptors, ...
                rowPropName, rowAdaptor, otherProps)
            obj@matlab.bigdata.internal.adaptors.AbstractAdaptor(className);

            assert(numel(varNames) == numel(varAdaptors) && matlab.internal.datatypes.isText(varNames, true), ...
                'Assertion failed: Variable names must be a cell array of characters that matches the number of variables.');
            varNames = cellstr(varNames);
            assert(ischar(rowPropName) && isrow(rowPropName), ...
                'Assertion failed: RowPropertyName must be a character row vector.');

            if numel(dimNames) ~= 2 || ~matlab.internal.datatypes.isText(dimNames, true)
                error(message('MATLAB:table:IncorrectNumberOfDimNames'))
            end
            dimNames = cellstr(dimNames);

            % Trim fields from properties if present.
            otherProps = iTrimOtherProperties(otherProps);

            % Assert correct contents of 'otherProps'.
            numVars = numel(varNames);
            assert(ismember(numel(otherProps.VariableDescriptions), [0 numVars]), ...
                'Assertion failed: VariableDescriptions must be empty or match number of variables.');
            assert(ismember(numel(otherProps.VariableUnits), [0 numVars]), ...
                'Assertion failed: VariableUnits must be empty or match number of variables.');
            if isfield(otherProps, 'VariableContinuity')
                assert(ismember(numel(otherProps.VariableContinuity), [0 numVars]), ...
                    'Assertion failed: VariableContinuity must be empty or match number of variables.');
            end

            asRow = @(x) reshape(x, 1, []);

            obj.DimensionNames        = asRow(dimNames);
            obj.DefaultDimensionNames = asRow(defaultDimNames);
            obj.VariableNames         = asRow(varNames);
            obj.VariableAdaptors      = asRow(varAdaptors);
            obj.RowPropertyName       = rowPropName;
            obj.RowAdaptor            = rowAdaptor;
            obj.OtherProperties       = otherProps;

            obj = setSmallSizes(obj, length(obj.VariableNames));
            for idx = 1:numel(obj.VariableAdaptors)
                obj.VariableAdaptors{idx} = copyTallSize(obj.VariableAdaptors{idx}, obj);
                obj.VariableAdaptors{idx}.ComputeMetadata = true;
            end
            if ~isempty(obj.RowAdaptor)
                obj.RowAdaptor = copyTallSize(obj.RowAdaptor, obj);
            end
            obj.ComputeMetadata = true;

            obj.VariableTallArraysCache = iBuildEmptyMap();  % Reset the name<=>data cache
        end

        function previewData = fabricateTabularPreview(obj, varNames)
            % Fabricate a preview table. If size is known and small,
            % make it the correct size, otherwise pretend it's unknown.
            if ~isnan(obj.Size(1)) && obj.Size(1)<matlab.bigdata.internal.util.defaultHeadTailRows()
                numRowsDesired = obj.Size(1);
            else
                % Default to 3
                numRowsDesired = 3;
            end

            % table constructor cannot handle a char row-vector as variable data, so we must
            % always ensure there are multiple rows, as per g1508983.
            var  = repmat('?', max(numRowsDesired, 2), 1);
            vars = repmat({var}, 1, numel(varNames));
            previewData = table(vars{:}, 'VariableNames', varNames);

            if height(previewData) > numRowsDesired
                % Truncate the additional rows we generated
                previewData = previewData(1:numRowsDesired, :);
            end
        end

        function sample = buildTabularSampleImpl(obj, constructor, defaultType, sz, preferSquareEmpty)
            %buildTabularSampleImpl Common implementation of
            % buildSampleImpl for tabular types.
            varAdaptors = obj.VariableAdaptors;
            % Use of max(..,2) is a workaround since creating a table
            % with a single row errors if one variable is a character
            % array.
            height = max(sz(1), 2);
            if isempty(obj.RowAdaptor)
                rowLabelSample = {};
            else
                rowLabelSample = buildSample(obj.RowAdaptor, defaultType, height);
            end
            varSamples = cellfun(@(a) buildSample(a, defaultType, height, preferSquareEmpty), ...
                varAdaptors, 'UniformOutput', false);
            sample = constructor(rowLabelSample, varSamples{:}, ...
                'VariableNames', obj.VariableNames, 'DimensionNames', obj.DimensionNames);
            if isempty(varSamples) && isempty(rowLabelSample)
                % If there were no actual input, sample has size [0,0]
                % instead of [height,0]. We need to correct this.
                sample.TestVar = zeros(sz(1), 0);
                sample.TestVar = [];
            else
                % Otherwise, we just correct for the workaround above.
                sample = sample(1 : sz(1), :);
            end
            sample.Properties = obj.OtherProperties;
        end
    end

    methods
        function names = getVariableNames(obj, optIdx)
            % Return the list of variable names for this table. If an index
            % is supplied, only the specified names are returned. optIdx
            % must be a numeric vector within indexing range or a logical
            % vector.
            if nargin>1
                names = obj.VariableNames(optIdx);
            else
                names = obj.VariableNames;
            end
        end

        function names = getDimensionNames(obj)
            % Return the dimension names.
            names = obj.DimensionNames;
        end

        function tf = usingDefaultDimensionNames(obj)
            % Is this table/timetable using default dimension names
            tf = isequal(obj.DimensionNames, obj.DefaultDimensionNames);
        end

        function w = width(obj)
            % width - return the number of (time)table variables for this adaptor.
            w = numel(obj.VariableAdaptors);
        end

        function clz = getVariableClass(obj, varIdentifier)
            % getVariableClass - get the class of a variable.
            % varIdentifier can be a scalar index or a char vector.
            [~, varIdx] = resolveVarNameSubscript(obj, varIdentifier);
            assert(isscalar(varIdx), 'getVariableClass operates only on scalar variables');
            clz = obj.VariableAdaptors{varIdx}.Class;
        end

        function adpt = getVariableAdaptor(obj, varIdentifier)
            % getVariableAdaptor - get the Adaptor of a variable.
            % varIdentifier can be any valid table variable specifier.
            [~, varIdx] = resolveVarNameSubscript(obj, varIdentifier);
            assert(isscalar(varIdx), 'getVariableAdaptor operates only on scalar variables. Use getVariableAdaptors instead.');
            adpt = obj.VariableAdaptors{varIdx};
        end

        function adpts = getVariableAdaptors(obj, varIdentifier)
            % getVariableAdaptors - get the Adaptors of several variables.
            % varIdentifier can be any valid table variable specifier.
            % The output is a cell array of adaptors.
            [~, varIdx] = resolveVarNameSubscript(obj, varIdentifier);
            adpts = obj.VariableAdaptors(varIdx);
        end

        function obj = setVariableAdaptor(obj, varIdentifier, adpt)
            % setVariableAdaptor - replace the Adaptor of one variable.
            % varIdentifier can be any valid table variable specifier.
            % adpt must be an adaptor with the same tall size as the table.
            [~, varIdx] = resolveVarNameSubscript(obj, varIdentifier);
            assert(isscalar(varIdx) && isscalar(adpt), 'setVariableAdaptor operates only on single variables.');
            assert(isequal(adpt.TallSize, obj.TallSize), 'setVariableAdaptor requires new adaptor to have same tall size as the table.');
            obj.VariableAdaptors{varIdx} = adpt;
        end

        function sz = getVariableSize(obj, varIdentifier)
            % getVariableSize - get the size of a variable.
            % varIdentifier can be a scalar index or a char vector.
            [~, varIdx] = resolveVarNameSubscript(obj, varIdentifier);
            assert(isscalar(varIdx), 'getVariableSize operates only on scalar variables');
            sz = obj.VariableAdaptors{varIdx}.Size;
        end

        function [nanFlagCell, precisionFlagCell] = interpretReductionFlags(~, FCN_NAME, flags)
            % Interpret flags passed to reduction functions (SUM, MEAN,
            % etc.) for table and timetable. Since these flags are just
            % passed on to the contents of the variables we accept the same
            % flags as the generic adaptor.
            [nanFlagCell, precisionFlagCell] = ...
                matlab.bigdata.internal.util.interpretGenericReductionFlags(FCN_NAME, flags);
        end

        function dim = getDefaultReductionDimIfKnown(obj) %#ok<MANU>
            % For tabular inputs reductions always work in dimension 1
            % unless specified otherwise.
            dim = 1;
        end

        function out = cat(dim, varargin)
            if dim == 1
                out = vertcat(varargin{:});
            else
                out = horzcat(varargin{:});
            end
        end

        function out = vertcat(varargin)
            % Combine multiple TableAdaptors for vertical concatenation of the underlying
            % tables. Note that varargin is a 1 x nargin cell array.
            varNames = cellfun(@(x) x.VariableNames, varargin, 'UniformOutput', false);
            nVars = cellfun(@(x) numel(x), varNames, 'UniformOutput', false);
            allVarNames = [varNames{:}];

            uniqueNumberOfVars = unique([nVars{:}]);
            uniqueVarNames = unique(allVarNames, "stable");
            if numel(uniqueNumberOfVars) ~= 1
                error(message('MATLAB:table:vertcat:SizeMismatch'));
            elseif ~isequal(numel(uniqueVarNames), uniqueNumberOfVars)
                error(message('MATLAB:table:vertcat:UnequalVarNames'));
            end

            firstTableAdaptor = varargin{1};
            tableWidth        = firstTableAdaptor.getSizeInDim(2);
            rowAdaptor        = firstTableAdaptor.RowAdaptor;
            newAdaptors       = iVertcatVariableAdaptors(varargin{:});
            oldProperties     = cellfun(@(x) x.OtherProperties, varargin, 'UniformOutput', false);
            newProperties     = iVertcatProperties(oldProperties, tableWidth);
            tallSizes         = cellfun(@(x) x.TallSize.Size, varargin);
            newSize           = sum(tallSizes);

            % We must take the dimension names from the first
            % table/timetable that has non-default names.
            idx = iFindNonDefaultDimNames(varargin{:});
            dimNames = varargin{idx}.DimensionNames;

            out = buildDerived(firstTableAdaptor, uniqueVarNames, newAdaptors, ...
                dimNames, rowAdaptor, newProperties);

            % Set the tall size of the out table adaptor to newSize
            if ~isnan(newSize)
                out = setSizeInDim(out, 1, newSize);
            end

            % We know that each column's tall size must be the same as the table's tall
            % size
            for i = 1:numel(out.VariableAdaptors)
                out.VariableAdaptors{i} = copyTallSize(out.VariableAdaptors{i}, out);
            end

        end

        function out = horzcat(varargin)
            % Combine multiple TableAdaptors for horizontal concatenation of the underlying
            % tables.
            allVarNames = cellfun(@(x) x.VariableNames, varargin, 'UniformOutput', false);
            allVarNames = [allVarNames{:}];

            [uniqueVarNames, ~, ic] = unique(allVarNames);
            if numel(allVarNames) ~= numel(uniqueVarNames)
                % find first duplicate, and error as per table/cat ...
                occurenceCount     = accumarray(ic, 1);
                firstNonUnique     = find(occurenceCount > 1, 1, 'first');
                assert(isscalar(firstNonUnique), ...
                    'Assertion failed: Could not find non-unique variable name.');
                firstNonUniqueName = uniqueVarNames{firstNonUnique};
                error(message('MATLAB:table:DuplicateVarNames', firstNonUniqueName));
            else
                % We must take the dimension names from the first
                % table/timetable that has non-default names.
                idx = iFindNonDefaultDimNames(varargin{:});
                dimNames          = varargin{idx}.DimensionNames;

                rowAdaptor        = varargin{1}.RowAdaptor;
                numVarsPerElement = cellfun(@(x) numel(x.VariableNames), varargin);
                oldProperties     = cellfun(@(x) x.OtherProperties, varargin, 'UniformOutput', false);
                newProperties     = iHorzcatProperties(oldProperties, numVarsPerElement);
                newVarNames       = reshape(allVarNames, 1, []);
                allAdaptors       = cellfun(@(x) x.VariableAdaptors, varargin, 'UniformOutput', false);
                newAdaptors       = [allAdaptors{:}];
                out               = buildDerived(varargin{1}, newVarNames, newAdaptors, ...
                    dimNames, rowAdaptor, newProperties);

                % Since we know that HORZCAT must involve only arrays that have the same size,
                % we can copy across the tall size from the first input.
                out = copyTallSize(out, varargin{1});
            end
        end

        function [newAdaptor, newVarNames] = joinBySample(fcn, requiresVarMerging, varargin)
            % Apply a join-like function handle to samples generated from
            % the provided adaptors. The provided function handle must
            % return tabular output such that:
            %  1) Has the correct width and VariableNames
            %  2) Propagate CustomProperties from the input.
            %
            % Syntax:
            %  [newAdaptor,newVarNames] = joinBySample(fcn,requiresVarMerging,adaptor1,adaptor2,..)
            %
            % Inputs:
            %   - fcn is a function handle with the signature:
            %
            %     sampleOut = fcn(sample1,sample2,..)
            %
            %     Where sampleN is a sample table of height 1 generated by
            %     adaptorN and sampleOut must be a table.
            %
            %   - requiresVarMerging must a scalar logical that is true if
            %     and only if an output table variable can consist of the
            %     merger of two input table variables. If true, joinBySample
            %     will take extra care with unknown sizes and types.
            %
            %   - adaptor1,adaptor2,.. each is a TabularAdaptor.
            %
            % Outputs:
            %   - newAdaptor is a TabularAdaptor that matches the output of
            %     invoking fcn on samples generated from the input
            %     adaptors. Uncertainty about size/type will be carried
            %     across.
            %
            %   - newVarNames is a cell array of character vectors of
            %     variable names from sampleOut.

            % For join/innerjoin, if any information is incomplete, we remove
            % all information of the same class for the purposes of sample
            % generation. This is to avoid comparing a sample against a sample
            % of unknown type.
            if requiresVarMerging
                isAllTypesKnown = all(cellfun(@isNestedTypeKnown, varargin));
                if ~isAllTypesKnown
                    varargin = cellfun(@resetNestedGenericType, varargin, 'UniformOutput', false);
                end

                isAllSmallSizesKnown = all(cellfun(@isNestedSmallSizeKnown, varargin));
                if ~isAllSmallSizesKnown
                    varargin = cellfun(@resetNestedSmallSizes, varargin, 'UniformOutput', false);
                end
            end

            % Sample generation. We will add a new custom property to keep
            % track of each variable origin. To do so, we create a new
            % property with a unique keyname "Source_" or with as many
            % trailing "_" characters so that it doesn't match with any
            % existing CustomProperty from all the tabular inputs.
            inSamples = cell(size(varargin));
            numUnderscores = zeros(size(varargin));
            for ii = 1 : numel(varargin)
                inSamples{ii} = buildSample(varargin{ii}, 'double');
                % There are some instances where the data has row names but
                % the adaptor isn't aware of it. For safety, we ensure row
                % names in all cases.
                if istable(inSamples{ii}) && isempty(inSamples{ii}.Properties.RowNames)
                    inSamples{ii}.Properties.RowNames = {'1'};
                end

                % Evaluate for this tabular input, what's the maximum
                % number of trailing "_" characters to create the new
                % custom property.
                propNames = fields(inSamples{ii}.Properties.CustomProperties);
                numUnderscoresAllVars = cellfun(@(name) sum(name == '_'), propNames);
                if isempty(numUnderscoresAllVars)
                    numUnderscores(ii) = 1;
                else
                    numUnderscores(ii) = max(numUnderscoresAllVars) + 1;
                end
            end

            % Once we have the maximum number of trailing "_" in each
            % input, take the maximum value and create the custom property
            % in each input.
            maxUnderscores = max(numUnderscores);
            for ii = 1 : numel(varargin)
                ourPropName = ['Source', repmat('_', 1, maxUnderscores)];
                inSamples{ii} = addprop(inSamples{ii}, ourPropName, "variable");

                % Set this new custom property for all the variables to
                % JoinOrigin reference strings.
                inSamples{ii}.Properties.CustomProperties.(ourPropName) = ...
                    cellstr("JoinOrigin_" + string(ii) + "_" + string(1:width(inSamples{ii})));
            end

            % Apply the provided function to the sample tables.
            %
            % We will use the output of this for two purposes:
            %  1. Generate an Adaptor to use to create the output adaptor
            %  2. Map output variables to input variables
            %
            % Item (2) is done by using "JoinOrigin_M_N" reference strings
            % in the created custom property. For all input samples, this
            % new custom property is set to "JoinOrigin_M_N", which
            % represents table variable N of input table M. The output
            % table sample custom property will contain either of the
            % following:
            %  - "JoinOrigin_M_N": From the corresponding input sample
            %  - 0x0 double: Default empty from table/stack
            try
                outSample = fcn(inSamples{:});
            catch err
                matlab.bigdata.internal.throw(err);
            end
            assert(istable(outSample) || istimetable(outSample), ...
                'Assertion failed: joinBySampleImpl requires fcn to emit a table.');

            % Now generate an adaptor for each output variable. This uses
            % the map of input to output variable to carry across
            % uncertainty about type and small sizes.
            %
            % Note, if an output table variable is derived from multiple
            % input variables, its type is defined by first one wins. This
            % will be the input variable referenced by "JoinOrigin_M_N".

            propNames = fields(outSample.Properties.CustomProperties);
            numUnderscores = cellfun(@(name) sum(name == '_'), propNames);
            [~, idxOurProp] = max(numUnderscores);
            ourOutProp = propNames{idxOurProp};

            origins = outSample.Properties.CustomProperties.(ourOutProp);
            % Identify empties from stack.
            idxEmpty = cellfun(@isempty, origins);
            origins(idxEmpty) = {''};
            origins = string(origins);

            newVarAdaptors = cell(width(outSample), 1);
            for ii = 1:width(outSample)
                origin = origins(ii);
                newAdaptor = matlab.bigdata.internal.adaptors.getAdaptor(outSample.(ii));
                if startsWith(origin, "JoinOrigin_")
                    idx = double(split(extractAfter(origin, 11), "_"));
                    assert(numel(idx) == 2 && all(~isnan(idx)), ...
                        'Assertion failed: Could not parse a JoinOrigin string');
                    % Carry across uncertainty about size/type from the
                    % origin input table variable from which this output
                    % variable is derived.
                    origAdaptor = varargin{idx(1)}.getVariableAdaptor(idx(2));
                    if ~origAdaptor.isNestedTypeKnown()
                        newAdaptor = resetNestedGenericType(newAdaptor);
                    end
                    if ~origAdaptor.isNestedSmallSizeKnown()
                        newAdaptor = resetNestedSmallSizes(newAdaptor);
                    end
                end
                newVarAdaptors{ii} = resetTallSize(newAdaptor);
            end

            % Now remove our property from the output sample.
            outSample = rmprop(outSample, ourOutProp);

            otherProps = outSample.Properties;
            newVarNames = otherProps.VariableNames;
            dimNames = otherProps.DimensionNames;

            newAdaptor = buildDerived(varargin{1}, newVarNames, newVarAdaptors, ...
                dimNames, varargin{1}.RowAdaptor, otherProps);
            newAdaptor = resetTallSize(newAdaptor);
        end

        function tf = isaVariableOfType(obj, vartypeSubscript)
            % isaVartype Return a logical vector indicating which variables
            % in this adaptor math vartypeSubscript, where vartypeSpec is a
            % vartype subscripter.
            tf = resolveVarTypeSubscript(obj, vartypeSubscript);
        end

        function tf = isNestedTypeKnown(obj)
            % isTypeKnown Return TRUE if and only if this adaptor and all
            % of its children have known type. Children include table
            % variables.
            tf = isTypeKnown(obj);
            for idx = 1:numel(obj.VariableAdaptors)
                tf = tf && isNestedTypeKnown(obj.VariableAdaptors{idx});
            end
        end

        function tf = isNestedSmallSizeKnown(obj)
            % Return true if both this adaptor and all its children have
            % known small size. Children include table variables.
            tf = isSmallSizeKnown(obj);
            for idx = 1:numel(obj.VariableAdaptors)
                tf = tf && isNestedSmallSizeKnown(obj.VariableAdaptors{idx});
            end
        end

        function obj = resetNestedGenericType(obj)
            %resetNestedGenericType Reset the type of any GenericAdaptor
            % found among this adaptor or any children of this adaptor.
            for idx = 1:numel(obj.VariableAdaptors)
                obj.VariableAdaptors{idx} = resetNestedGenericType(obj.VariableAdaptors{idx});
            end
        end

        function obj = resetCategories(obj)
            % Reset categories in the categorical variable adaptors if
            % there are any. Loop over variables that are also table or
            % timetable.
            for idx = 1:numel(obj.VariableAdaptors)
                if ismember(obj.VariableAdaptors{idx}.Class, ["categorical" "table" "timetable"])
                    obj.VariableAdaptors{idx} = resetCategories(obj.VariableAdaptors{idx});
                end
            end
        end

        function idxs = resolveVarNamesToIdxs(obj, namesOrIdxs)
            [~, idxs] = obj.resolveVarNameSubscript(namesOrIdxs);
        end

        function obj = resetSizeInformation(obj)
            % Overloaded for TabularAdaptor - NDims and num variables don't change.
            obj.VariableTallArraysCache = iBuildEmptyMap(); % Reset the name<=>data cache
            obj = resetTallSize(obj);
        end

        function obj = resetTallSize(obj)
            % Override resetTallSize to also recurse into the variables
            obj.VariableTallArraysCache = iBuildEmptyMap(); % Reset the name<=>data cache
            obj = resetTallSize@matlab.bigdata.internal.adaptors.AbstractAdaptor(obj);
            obj = copyTallSizeToAllSubAdaptors(obj);
        end

        function obj = setTallSize(obj, m)
            % Override setTallSize to also recurse into the variables
            obj.VariableTallArraysCache = iBuildEmptyMap(); % Reset the name<=>data cache
            obj = setTallSize@matlab.bigdata.internal.adaptors.AbstractAdaptor(obj, m);
            obj = copyTallSizeToAllSubAdaptors(obj);
        end

        function obj = copyTallSize(obj, copyFrom)
            % Override copyTallSize to also recurse into the variables
            obj.VariableTallArraysCache = iBuildEmptyMap(); % Reset the name<=>data cache
            obj = copyTallSize@matlab.bigdata.internal.adaptors.AbstractAdaptor(obj, copyFrom);
            obj = copyTallSizeToAllSubAdaptors(obj);
        end

        function obj = resetNestedSmallSizes(obj)
            %resetNestedSmallSizes Reset the small size of both this
            % adaptor and any children. Children include table variables.

            % This does not reset the RowAdaptor because that is required
            % by the tabular contract to be a column vector.
            for idx = 1:numel(obj.VariableAdaptors)
                obj.VariableAdaptors{idx} = resetNestedSmallSizes(obj.VariableAdaptors{idx});
            end
        end

        function obj = copySizeInformation(obj, copyFrom)
            % Overloaded for TableAdaptor - only copy the tall size, and propagate to
            % contained variables.
            obj.VariableTallArraysCache = iBuildEmptyMap(); % Reset the name<=>data cache
            obj = copyTallSize(obj, copyFrom);
            obj = copyTallSizeToAllSubAdaptors(obj);
        end

        function displayImpl(obj, context, ~)
            if context.IsPreviewAvailable
                doDisplay(context);
            else
                previewData = fabricatePreview(obj);
                classOfPreview = obj.Class;
                doDisplayWithFabricatedPreview(context, previewData, classOfPreview, obj.NDims, obj.Size);
            end
        end

        function obj = copyCompatibleInformation(obj, copyFrom)
            % Copy compatible information from one adaptor to another.
            % A piece of information is compatible with a target adaptor if
            % that information could be valid for the underlying data.
            %
            % See matlab.bigdata.internal.adaptors.AbstractAdaptor/copyCompatibleInformation

            % Don't even try unless both inputs are the right kind of
            % tabular with the right width. Tables are only compatible with
            % other tables of the same variables.
            if ~isequal(obj.Class, copyFrom.Class) ...
                    || ~isequal(obj.VariableNames, copyFrom.VariableNames)
                return;
            end

            for ii = 1:numel(obj.VariableAdaptors)
                obj.VariableAdaptors{ii} = copyCompatibleInformation(...
                    obj.VariableAdaptors{ii}, copyFrom.VariableAdaptors{ii});
            end
        end

        function names = getProperties(obj)
            names = [obj.VariableNames, 'Properties', obj.DimensionNames];
        end
    end

    methods % Indexing
        function varargout = subsrefDot(obj, pa, ~, s)
            if isequal(s(1).subs, 'Properties')
                out = getPropertiesStruct(obj, pa);
            elseif isequal(s(1).subs, obj.DimensionNames{1})
                % Getting the rowtimes vector
                out = obj.getRowProperty(pa);
            elseif isequal(s(1).subs, obj.DimensionNames{2})
                if ~isscalar(s)
                    error(message('MATLAB:table:NestedSubscriptingWithDotVariables', ...
                        s(1).subs));
                end
                out = subsrefTabularVar('.', {s(1).subs}, false, pa);
                dim = 2;
                adaptor = matlab.bigdata.internal.adaptors.combineAdaptors(...
                    dim, obj.VariableAdaptors);
                out = tall(out, adaptor);
            else
                allowMissing = false;
                varName = obj.resolveDotSubscript(s(1).subs, allowMissing);
                if isnumeric(obj.VariableTallArraysCache)
                    obj.VariableTallArraysCache = iBuildEmptyMap();
                end
                if isKey(obj.VariableTallArraysCache, varName)
                    % We have extracted this variable from the table before, so return it
                    % again. Safe because values inside tall arrays are
                    % immutable (i.e. SUBSASGN returns a fresh tall array).
                    out = obj.VariableTallArraysCache(varName);
                else
                    % Extract the variable from the table
                    out = subsrefTabularVar('.', {varName}, false, pa);
                    adaptor = obj.VariableAdaptors{string(varName) == obj.VariableNames};
                    out = tall(out, adaptor);
                    obj.VariableTallArraysCache(varName) = out;
                end
            end
            [varargout{1:nargout}] = iRecurseSubsref(out, s(2:end));
        end

        function varargout = subsrefBraces(obj, pa, ~, s)
            if isscalar(s(1).subs)
                error(message('MATLAB:table:LinearSubscript'));
            elseif numel(s(1).subs) ~= 2
                error(message('MATLAB:table:NDSubscript'));
            end
            [firstSub, secondSub] = deal(s(1).subs{:});
            errorIfFirstSubSelectingRowsNotSupported(obj,firstSub);

            [secondSubVarNames, secondSubNumeric] = obj.resolveVarNameSubscript(secondSub);

            outValue = subsrefTabularVar('{}', {secondSubVarNames}, false, pa);
            dim      = 2;
            if isempty(secondSubNumeric)
                % table brace indexing selecting an empty list of variables returns Nx0 double.
                adaptor = matlab.bigdata.internal.adaptors.getAdaptorForType('double');
            elseif isscalar(secondSubNumeric)
                adaptor = obj.VariableAdaptors{secondSubNumeric};
            else
                adaptor = matlab.bigdata.internal.adaptors.combineAdaptors(...
                    dim, obj.VariableAdaptors(secondSubNumeric));
            end

            isFirstSubColon = matlab.bigdata.internal.util.isColonSubscript(firstSub);
            if isFirstSubColon
                % ensure the new array has linked tall size information from this object.
                adaptor = copyTallSize(adaptor, obj);
            end
            out = tall(outValue, adaptor);

            % Use tall subsref to select rows. Note that this is a rather imperfect
            % implementation as it presumes no more than 3 non-tall dimensions.
            if ~isFirstSubColon
                newSubs = cell(1,4);
                newSubs{1} = firstSub;
                newSubs(2:end) = {':'};
                out = subsref(out, substruct('()', newSubs));
            end

            [varargout{1:nargout}] = iRecurseSubsref(out, s(2:end));
        end

        function obj = subsasgnBraces(~, ~, ~, ~, ~) %#ok<STOUT>
            error(message('MATLAB:bigdata:table:SubsasgnBracesNotSupported'))
        end

        function out = subsrefParens(obj, pa, szPa, s)
            if isscalar(s(1).subs)
                error(message('MATLAB:table:LinearSubscript'));
            elseif numel(s(1).subs) ~= 2
                error(message('MATLAB:table:NDSubscript'));
            end

            [firstSub, secondSub] = deal(s(1).subs{:});
            errorIfFirstSubSelectingRowsNotSupported(obj,firstSub);

            % First off, subselect the columns specified by secondSub
            [varNames, varIdxs] = obj.resolveVarNameSubscript(secondSub);
            if ~isequal(varNames, obj.VariableNames)
                selectedColumnsPa = subsrefTabularVar('()', {varNames}, false, pa);
            else
                selectedColumnsPa = pa;
            end
            selectedAdaptors = obj.VariableAdaptors(varIdxs);
            newProps = obj.OtherProperties;

            % For each of the following properties, if they are non-empty, copy across only
            % the appropriate elements as indexed by varIdxs.
            propsToFilter = {'VariableUnits', 'VariableDescriptions', 'VariableContinuity'};
            for idx = 1:numel(propsToFilter)
                thisProp = newProps.(propsToFilter{idx});
                if ~isempty(thisProp)
                    newProps.(propsToFilter{idx}) = thisProp(varIdxs);
                end
            end

            % Now handle custom properties.
            tableWidth = obj.getSizeInDim(2);
            newProps.CustomProperties = iIndexCustomProp(newProps.CustomProperties, varIdxs, tableWidth);

            % Make selected varNames unique then build the output adaptor
            varNames = matlab.lang.makeUniqueStrings(varNames, {}, namelengthmax);
            newAdaptor = buildDerived(obj, varNames, selectedAdaptors, ...
                obj.DimensionNames, obj.RowAdaptor, newProps);

            % Next, perform the row selection
            [selectedRowsAndColumnsPa, isTallSizeUnchanged, newTallSize] = ...
                subsrefParensImpl(selectedColumnsPa, szPa, ...
                substruct('()', {firstSub, ':'}));
            if isTallSizeUnchanged
                newAdaptor = copyTallSize(newAdaptor, obj);
            elseif ~isnan(newTallSize)
                % Update tall size in-place
                setTallSize(newAdaptor, newTallSize);
            end
            % Build the tall table
            tmp = tall(selectedRowsAndColumnsPa, newAdaptor);

            % and then recurse
            out = iRecurseSubsref(tmp, s(2:end));
        end

        function pa = subsasgnParens(obj, pa, szPa, s, b) %#ok<INUSD>
            error(message('MATLAB:bigdata:table:SubsasgnParensNotSupported', obj.Class));
        end

        function out = subsasgnParensDeleting(obj, pa, szPa, s)
            import matlab.bigdata.internal.util.isColonSubscript

            % The language front-end should not permit expressions where there is any form
            % of indexing following parens.
            assert(isscalar(s), ...
                'Assertion failed: Multiple levels of indexing passed to subsasgnParensDeleting implementation.');
            if isscalar(s(1).subs)
                error(message('MATLAB:table:LinearSubscript'));
            elseif numel(s(1).subs) ~= 2
                error(message('MATLAB:table:NDSubscript'));
            end

            [firstSub, secondSub] = deal(s(1).subs{:});

            if isColonSubscript(secondSub)
                % Delete whole slices
                if isColonSubscript(firstSub)
                    error(message('MATLAB:bigdata:table:DeleteWholeTableUsingIndexing'));
                elseif ~istall(firstSub)
                    error(message('MATLAB:bigdata:table:FirstSubscriptColonOrTallVariable'));
                end

                % Here we know we're left with a tall subscript in first place, we need to
                % negate it (providing it's logical)
                firstSub = tall.validateType(firstSub, 'subsasgn', {'logical'}, 1);
                out = obj.subsrefParens(pa, szPa, substruct('()', {~firstSub, secondSub}));
            else
                if matlab.bigdata.internal.util.isColonSubscript(firstSub)
                    % Deleting whole variables - negate the variable list
                    deleteNames = obj.resolveVarNameSubscript(secondSub);
                    keepNames = setdiff(obj.VariableNames, deleteNames, 'stable');
                    out = obj.subsrefParens(pa, szPa, substruct('()', {firstSub, keepNames}));
                else
                    error(message('MATLAB:table:InvalidEmptyAssignment'));
                end
            end

        end

        function out = subsasgnDot(obj, pa, szPa, s, b)
            if isequal(s(1).subs, 'Properties')
                out = subsasgnDotProperties(obj, pa, szPa, s, b);
                return
            end
            if isequal(s(1).subs, obj.DimensionNames{2})
                error(message('MATLAB:bigdata:table:SetVariablesUnsupported', ...
                    obj.DimensionNames{2}));
            end
            allowMissing = true;
            varName = obj.resolveDotSubscript(s(1).subs, allowMissing);

            if isscalar(s)
                % Adding or updating a whole variable.
                if ~istall(b)
                    % Note there's no scalar expansion for "t.x = b".
                    error(message('MATLAB:bigdata:table:AssignVariableMustBeTall'));
                end

                bAdaptor = matlab.bigdata.internal.adaptors.getAdaptor(b);

                % Get the tall size of LHS and RHS - either can be NaN.
                objTallSize = obj.getSizeInDim(1);
                bTallSize   = bAdaptor.getSizeInDim(1);

                % If both tall sizes are non-NaN and non-equal, there's a problem.
                if ~isnan(objTallSize) && ~isnan(bTallSize) && objTallSize ~= bTallSize
                    error(message('MATLAB:bigdata:array:IncompatibleTallStrictSize'));
                end

                % Build a new adaptor
                names = obj.VariableNames;
                adaptors = obj.VariableAdaptors;

                rowPropName = obj.DimensionNames{1};

                if isequal(s(1).subs, rowPropName)
                    % Updating the row property
                    newAdaptor = buildDerived(obj, names, adaptors, obj.DimensionNames, ...
                        bAdaptor, obj.OtherProperties);
                else
                    newProps = obj.OtherProperties;
                    if ~ismember(varName, names)
                        tableWidth = numel(names);
                        names{end+1} = varName;
                        if ~isempty(newProps.VariableDescriptions)
                            newProps.VariableDescriptions{end+1} = '';
                        end
                        if ~isempty(newProps.VariableUnits)
                            newProps.VariableUnits{end+1} = '';
                        end
                        if ~isempty(newProps.VariableContinuity)
                            newProps.VariableContinuity(end+1) = matlab.tabular.Continuity.unset;
                        end
                        newProps.CustomProperties = iAddVarCustomProps(newProps.CustomProperties, tableWidth);
                    end
                    idx = find(strcmp(varName, names));
                    assert(isscalar(idx), ...
                        'Assertion failed: Could not find variable ''%s'' in subsasgnDot.', varName);
                    adaptors{idx} = bAdaptor;

                    newAdaptor = buildDerived(obj, names, adaptors, obj.DimensionNames, ...
                        obj.RowAdaptor, newProps);
                end
                outPa = strictslicefun(@(t, v) iUpdateWholeVariable(t, varName, v), ...
                    pa, hGetValueImpl(b));
                out = tall(outPa, newAdaptor);
            else
                % Replacing part of variable - extract, update, replace.
                tallVar = obj.subsrefDot(pa, szPa, s(1));
                tallVar = subsasgn(tallVar, s(2:end), b);
                out     = obj.subsasgnDot(pa, szPa, substruct('.', varName), tallVar);
            end
        end

        function out = subsasgnDotDeleting(obj, pa, ~, S)
            if ~isscalar(S)
                error(message('MATLAB:bigdata:table:DotDeletingSingleLevelIndexing'));
            end

            if isequal(S(1).subs, obj.DimensionNames{1})
                throwCannotDeleteRowPropertyError(obj);
            end
            if isequal(S(1).subs, obj.DimensionNames{2})
                error(message('MATLAB:bigdata:table:DeleteAllVariablesUnsupported', ...
                    obj.DimensionNames{2}));
            end

            allowMissing = false;
            deletingName = obj.resolveDotSubscript(S(1).subs, allowMissing);
            % Need to work out which index we're removing
            deletingTF = strcmp(deletingName, obj.VariableNames);
            outPa = slicefun(@(x) iRemoveVariable(x, deletingName), pa);

            newVars = obj.VariableNames(~deletingTF);
            newVarAdaptors = obj.VariableAdaptors(~deletingTF);
            newProps = obj.OtherProperties;
            if ~isempty(newProps.VariableUnits)
                newProps.VariableUnits = newProps.VariableUnits(~deletingTF);
            end
            if ~isempty(newProps.VariableDescriptions)
                newProps.VariableDescriptions = newProps.VariableDescriptions(~deletingTF);
            end

            newAdaptor = buildDerived(obj, newVars, newVarAdaptors, obj.DimensionNames, ...
                obj.RowAdaptor, newProps);
            out = tall(outPa, newAdaptor);
        end

        function out = subsasgnDotProperties(adap, pa, szPa, s, b)
            % Set the properties struct, or one of its fields. The error
            % checking for this is complex, so we use a local table to do
            % it for us.

            % First check for setting the row property (RowTimes, RowNames)
            % as this is the only property allowed to have tall input.
            rowSubs = substruct('.','Properties', '.', adap.RowPropertyName);
            if isequal(s, rowSubs)
                out = subsasgnRowProperty(adap, pa, szPa, b);
                return
            end

            % If assigning the whole properties struct, we must skip the
            % row property and do it afterwards.
            setPropStructWithRows = isequal(s, substruct('.','Properties')) ...
                && isfield(b, adap.RowPropertyName);

            if setPropStructWithRows
                rowVals = b.(adap.RowPropertyName);
                b = rmfield(b, adap.RowPropertyName);
            end

            width = numel(adap.VariableNames);
            proto = adap.buildSample('double', [0, width]);
            % This will throw if incorrect, including non-existing
            % properties and properties with wrong case.
            proto = subsasgn(proto, s, b);

            % Now check for non-supported properties, error if the user
            % attempts to set a property that is not yet supported for tall
            % timetables or tall tables.
            if isa(adap.getPropertiesStruct(pa), 'matlab.tabular.TallTimetableProperties')
                nonSupportedProps = matlab.bigdata.internal.adaptors.TimetableAdaptor.listNonSupportedProperties();
                tabularType = "Timetable";
            elseif isa(adap.getPropertiesStruct(pa), 'matlab.tabular.TallTableProperties')
                nonSupportedProps = matlab.bigdata.internal.adaptors.TableAdaptor.listNonSupportedProperties();
                tabularType = "Table";
            end

            if isequal(s, substruct('.','Properties'))
                propNames = string(fieldnames(b));
                isNonSupported = contains(propNames, nonSupportedProps);
            else
                [isNonSupported, propNames] = arrayfun(@(x) deal(contains(x.subs, nonSupportedProps), string(x.subs)), s(2));
            end
            if any(isNonSupported)
                propNames = propNames(isNonSupported);
                % In the case of the struct, it might be the case that
                % more than one property is not supported. Report the
                % first one only.
                error(message(sprintf('MATLAB:bigdata:array:Unsupported%sProperty', tabularType), propNames(1)));
            end

            % Now create a new adaptor with these properties
            adap.DimensionNames = proto.Properties.DimensionNames;
            adap.VariableNames = proto.Properties.VariableNames;
            adap.OtherProperties = iTrimOtherProperties(proto.Properties);

            % Apply the changes to the remote content too
            outPa = elementfun( @(x) iDoSubsasgn(x,s,b), pa );

            if setPropStructWithRows
                % Apply the row values. Note that this will build the tall array for us.
                out = subsasgnRowProperty(adap, outPa, szPa, rowVals);
            else
                % Nothing more to do. Build the output tall array.
                out = tall(outPa, adap);
            end

        end
    end

    methods (Static, Hidden)
        function t = copyOtherTabularProperties(t, tCopyFrom)
            % Copy OtherPropertiesFields from tCopyFrom to t and keep the
            % rest of properties in t. t contains a subset of variables of
            % tCopyFrom. Please note that VariableNames and DimensionNames
            % are not included in OtherPropertiesFields.
            adaptorTCopyFrom = matlab.bigdata.internal.adaptors.getAdaptor(tCopyFrom);
            adaptorT = matlab.bigdata.internal.adaptors.getAdaptor(t);
            allVars = adaptorTCopyFrom.VariableNames;
            varNames = adaptorT.VariableNames;
            [~, idx] = ismember(varNames, allVars);
            assert((all(idx>0) && ~isempty(varNames)) || (isempty(idx) && isempty(varNames)), ...
                'Assertion failed: Variables must exist in the table where we copy other properties from.')

            % Copy only the relevant properties for the subset of variables
            % in t. Keep the rest of properties as they are in t.
            props = adaptorTCopyFrom.OtherProperties;
            otherProperties = fields(props);
            newProps = struct(getPropertiesStruct(adaptorT, hGetValueImpl(t)));
            for ii = 1:numel(otherProperties)
                thisProp = props.(otherProperties{ii});
                % If it's a "variable-based" property, only copy the
                % corresponding value for the variables in t.
                if ~isempty(thisProp) && startsWith(otherProperties{ii}, 'Variable')
                    if isempty(idx)
                        % t has no variable names, return 1x0 empties
                        thisProp = thisProp(1, []);
                    else
                        thisProp = thisProp(idx);
                    end
                end
                newProps.(otherProperties{ii}) = thisProp;
            end

            % Now handle CustomProperties separately, they can be set per table or per
            % variable. If it's per variable, we'll only need to copy the data for
            % the variables that exist in t.
            newProps.CustomProperties = iIndexCustomProp(props.CustomProperties, idx, width(tCopyFrom));

            % Assign the updated properties to t.
            t = subsasgn(t, substruct('.', 'Properties'), newProps);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function t = iRemoveVariable(t, varName)
t.(varName) = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simply apply a new variable into the table, ensuring the new data is the
% correct size. The check here is only needed in rare cases (i.e. where the
% table is completely empty) - otherwise the table assignment itself actually
% throws this error. See g1367363.
function t = iUpdateWholeVariable(t, varName, v)
if size(t,1) ~= size(v,1)
    error(message('MATLAB:table:RowDimensionMismatch'));
end
t.(varName) = v;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Apply remaining indexing expressions
function varargout = iRecurseSubsref(data, S)
import matlab.lang.correction.ReplaceIdentifierCorrection

if isempty(S)
    varargout = {data};
elseif isa(data, 'matlab.tabular.TallTimetableProperties') ...
        || isa(data, 'matlab.tabular.TallTableProperties')
    % Handle separately non-supported properties for tall
    % tables/timetables, supported properties with a wrong case, and
    % non-existing properties.
    try
        [varargout{1:nargout}] = subsref(data, S);
    catch ME
        if ME.identifier == "MATLAB:noSuchMethodOrField"
            propName = S.subs;
            if isa(data, 'matlab.tabular.TallTimetableProperties')
                nonSupportedProps = matlab.bigdata.internal.adaptors.TimetableAdaptor.listNonSupportedProperties();
                tabularType = "Timetable";
            elseif isa(data, 'matlab.tabular.TallTableProperties')
                nonSupportedProps = matlab.bigdata.internal.adaptors.TableAdaptor.listNonSupportedProperties();
                tabularType = "Table";
            end
            if ismember(propName, nonSupportedProps)
                error(message(sprintf('MATLAB:bigdata:array:Unsupported%sProperty', tabularType), propName));
            end
            supportedProps = string(properties(data));
            match = matches(supportedProps, propName, 'IgnoreCase', true);
            if any(match)
                % Error and suggest the correct variable name and syntax.
                match = supportedProps(match);
                throw(MException(message('MATLAB:table:UnknownPropertyCase', propName, match)) ...
                    .addCorrection(ReplaceIdentifierCorrection(propName, match)));
            end
            error(message('MATLAB:table:UnknownProperty', propName));
        else
            throw(ME);
        end
    end
else
    [varargout{1:nargout}] = subsref(data, S);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Combine 'OtherProperties' from a table during HORZCAT
function out = iHorzcatProperties(propCell, numVarsPerElement)

% Start out by copying the OtherProperties from the first item.
out               = propCell{1};

% Get an array describing how many variables each element of propCell
% corresponds to.
totalNumVars      = sum(numVarsPerElement);

% When building up the concatenating elements, we need to know where to start
% placing the outputs for each element of propCell.
varStartIdx       = cumsum([1, numVarsPerElement]);

% We need to concatenate VariableDescriptions and VariableUnits if any is non-empty
propsToConcat     = {'VariableDescriptions', 'VariableUnits', 'VariableContinuity'};
emptyVal          = {{''}, {''}, matlab.tabular.Continuity.unset };

for idx = 1:numel(propsToConcat)
    thisProp = propsToConcat{idx};
    if ~all(cellfun(@(x) isempty(x.(thisProp)), propCell))
        % Some are non-empty, need to concatenate all.
        thisEmptyVal = emptyVal{idx};
        newValue = repmat(thisEmptyVal, 1, totalNumVars);
        for jdx = 1:numel(propCell)
            propForThisElement = propCell{jdx}.(thisProp);
            if ~isempty(propForThisElement)
                assignRange = varStartIdx(jdx):(varStartIdx(jdx+1) - 1);
                newValue(assignRange) = propForThisElement;
            end
        end
        out.(thisProp) = newValue;
    end
end

% Finally deal with custom properties
custPropCell = cellfun(@(x) x.CustomProperties, propCell, 'UniformOutput', false);
out.CustomProperties = iHorzcatCustomProps(custPropCell, numVarsPerElement);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Combine 'OtherProperties' from a table during VERTCAT
function out = iVertcatProperties(propCell, tableWidth)

% Start out by copying the OtherProperties from the first item.
out = propCell{1};

% Vertcat should take the first non-empty value for each property in the input
% tables
propNames = fieldnames(out);
for idx = 1:numel(propNames)
    thisProp = propNames{idx};
    idxFirstNonEmpty = find(cellfun(@(x) ~isempty(x.(thisProp)), propCell), 1);
    if ~isempty(idxFirstNonEmpty)
        out.(thisProp) = propCell{idxFirstNonEmpty}.(thisProp);
    end
end
% Except custom properties, which can combine multiple tables together
custPropCell = cellfun(@(x) x.CustomProperties, propCell, 'UniformOutput', false);
out.CustomProperties = iVertcatCustomProps(custPropCell, tableWidth);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Combine table variable adaptors for VERTCAT
function out = iVertcatVariableAdaptors(varargin)
% For each vertcat input, use the rules defined in combineAdaptors to merge
% the variable adaptors for the final output table.

import matlab.bigdata.internal.adaptors.combineAdaptors

out = varargin{1}.VariableAdaptors;

for ii=2:numel(varargin)
    nextAdaptors = varargin{ii}.VariableAdaptors;

    for jj=1:numel(out)
        try
            out{jj} = combineAdaptors(1, {out{jj}, nextAdaptors{jj}});
        catch
            failedVariableName = varargin{1}.VariableNames{jj};

            error(message('MATLAB:table:vertcat:VertcatMethodFailed', ...
                failedVariableName));
        end
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Build an empty name-value map
function map = iBuildEmptyMap()
map = containers.Map('KeyType', 'char', ...
    'ValueType', 'any');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Trim a table properties structure to store in OtherProperties
function props = iTrimOtherProperties(props)
propsToRetain  = matlab.bigdata.internal.adaptors.TabularAdaptor.OtherPropertiesFields;
props          = struct(props);
fieldsToRemove = setdiff(fieldnames(props), propsToRetain);
props          = rmfield(props, fieldsToRemove);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform a subsasgn on the remote content
function x = iDoSubsasgn(x,s,b)
if istable(x) || istimetable(x)
    x = subsasgn(x,s,b);
end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add an extra element to all custom properties of type "Variable"
function custProp = iAddVarCustomProps(custProp, tableWidth)
t = table.empty(0, tableWidth);
t.Properties.CustomProperties = custProp;
t.(tableWidth + 1) = {};
custProp = t.Properties.CustomProperties;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Manipulate custom properties of type "Variable" to correspond with how
% the table was indexed
function custProp = iIndexCustomProp(custProp, varIdx, tableWidth)
t = table.empty(0, tableWidth);
t.Properties.CustomProperties = custProp;
t = t(:, varIdx);
custProp = t.Properties.CustomProperties;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Combine multiple custom property objects as if the table had been vertcat
function custProp = iVertcatCustomProps(custPropCell,tableWidth)
t = cell(size(custPropCell));
for ii = 1:numel(custPropCell)
    t{ii} = table.empty(0, tableWidth);
    t{ii}.Properties.CustomProperties = custPropCell{ii};
end
t = vertcat(t{:});
custProp = t.Properties.CustomProperties;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Combine multiple custom property objects as if the table had been horzcat
function custProp = iHorzcatCustomProps(custPropCell, tableWidths)
t = cell(size(custPropCell));
for ii = 1:numel(custPropCell)
    vars = cell(tableWidths(ii), 1);
    t{ii} = table(vars{:}, 'VariableNames', "Var" + ii + "_" + (1:tableWidths(ii)));
    t{ii}.Properties.CustomProperties = custPropCell{ii};
end
t = [t{:}];
custProp = t.Properties.CustomProperties;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find the first table/timetable that has non-default dimension names
function idx = iFindNonDefaultDimNames(varargin)
idx = find(~cellfun(@usingDefaultDimensionNames, varargin), 1, "first");
if isempty(idx)
    idx = 1;
end
end
