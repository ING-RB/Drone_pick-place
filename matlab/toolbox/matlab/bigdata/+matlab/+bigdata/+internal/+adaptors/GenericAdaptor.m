%GenericAdaptor Adaptor for generic data.

% Copyright 2016-2022 The MathWorks, Inc.
classdef GenericAdaptor < ...
        matlab.bigdata.internal.adaptors.AbstractAdaptor & ...
        matlab.bigdata.internal.adaptors.GeneralArrayParenIndexingMixin & ...
        matlab.bigdata.internal.adaptors.GeneralArrayDisplayMixin

    methods (Access = protected)
        function m = buildMetadataImpl(obj)
            m = matlab.bigdata.internal.adaptors.NumericishMetadata(obj.TallSize);
        end
    end
    methods
        function obj = GenericAdaptor(clz)
            if nargin < 1
                clz = '';
            else
                if ~isempty(clz)
                    if ~ismember(clz, matlab.bigdata.internal.adaptors.getAllowedTypes())
                        error(message('MATLAB:bigdata:array:TypeNotAllowed', clz));
                    end
                    % Check we're not trying to make a generic adaptor for
                    % a strong type.
                    assert(~ismember(clz, matlab.bigdata.internal.adaptors.getStrongTypes()), ...
                        'MATLAB:bigdata:array:AssertStrongType', ...
                        'GenericAdaptor being constructed with strong type.');
                end
            end
            obj@matlab.bigdata.internal.adaptors.AbstractAdaptor(clz);
        end

        function varargout = subsrefBraces(~, ~, ~, ~) %#ok<STOUT>
            error(message('MATLAB:bigdata:array:SubsrefBracesNotSupported'));
        end
        function obj = subsasgnBraces(~, ~, ~, ~, ~) %#ok<STOUT>
            error(message('MATLAB:bigdata:array:SubsasgnBracesNotSupported'));
        end
        
        function names = getProperties(~)
            names = cell(0,1);
        end

        function [nanFlagCell, precisionFlagCell] = interpretReductionFlags(~, FCN_NAME, flags)
            % Check and return reduction flags for generic numeric-ish
            % types. This should be used to get flags like 'omitnan' for
            % calls to SUM, PROD, etc.
            [nanFlagCell, precisionFlagCell] = ...
                matlab.bigdata.internal.util.interpretGenericReductionFlags(FCN_NAME, flags);
        end
        
        function tf = isTypeKnown(obj)
            % isTypeKnown Return TRUE if and only if this adaptor has known
            % type.
            tf = ~isempty(obj.Class);
        end
        
        function obj = resetNestedGenericType(obj)
            %resetNestedGenericType Reset the type of any GenericAdaptor
            % found among this adaptor or any children of this adaptor.
            
            obj = copySizeInformation(matlab.bigdata.internal.adaptors.GenericAdaptor(), obj);
        end
    end

    methods (Access=protected)
        % Build a sample of the underlying data.
        function sample = buildSampleImpl(obj, defaultType, sz, ~)
            clz = obj.Class;
            if isempty(clz)
                clz = defaultType;
            end
            if clz == "cell"
                sample = repmat({'1'}, sz);
            elseif clz == "logical"
                sample = true(sz);
            elseif clz == "char"
                sample = repmat('1', sz);
            else
                % Value 49 is ASCII for '1'. We pick this value to ensure
                % all samples have the same value as each other regardless
                % of class.
                sample = 49 * ones(sz, clz);
            end
        end
    end
end

