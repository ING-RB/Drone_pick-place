% parallel.parfor.Options Base class for parforOptions.

% Copyright 2018-2022 The MathWorks, Inc.

classdef (Abstract) Options < handle & matlab.mixin.CustomDisplay
    methods (Abstract)
        createEngine(obj, initData, parforF, numIterates)
    end

    methods (Abstract, Access = protected)
        getSpecificPropertyGroup(obj)
    end
    
    properties (SetAccess = immutable)
        RangePartitionMethod = 'auto'
        SubrangeSize (1,1) double = NaN
    end
    
    methods
        function obj = Options(parserResults, unspecifiedProperties)
            if nargin > 0
                obj.RangePartitionMethod = convertStringsToChars(...
                    parserResults.RangePartitionMethod);
                isSubrangeSizeSpecified = ~ismember('SubrangeSize', unspecifiedProperties);
                if strcmp(obj.RangePartitionMethod, 'fixed')
                    if ~isSubrangeSizeSpecified
                        error(message('MATLAB:parallel:parfor:OptionsSubrangeSizeRequired'));
                    end
                else
                    if isSubrangeSizeSpecified
                        error(message('MATLAB:parallel:parfor:OptionsSubrangeSizeForbidden'));
                    end
                end
                obj.SubrangeSize = parserResults.SubrangeSize;
            end
        end
        
    end
    methods (Access = protected)
        function propGroups = getPropertyGroups(obj)
            if ~isscalar(obj)
                propGroups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else
                baseGroup = struct('RangePartitionMethod', obj.RangePartitionMethod);
                if strcmp(obj.RangePartitionMethod, "fixed")
                   baseGroup.SubrangeSize = obj.SubrangeSize;
                end
                baseGroup = matlab.mixin.util.PropertyGroup(baseGroup);
                specificGroup = getSpecificPropertyGroup(obj);
                propGroups = [baseGroup, specificGroup];
            end
        end
    end
    
    methods (Static, Access = protected)
        function p = getBaseOptionsParser()
            p = inputParser();
            p.addParameter('RangePartitionMethod', 'auto', @iValidatePartitionMethod);
            p.addParameter('SubrangeSize', NaN, ...
                           @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive', 'integer'}));
        end
    end
end

function iValidatePartitionMethod(method)
    ok = false;
    if isa(method, 'function_handle')
        ok = true;
    elseif matlab.internal.datatypes.isScalarText(method)
        ok = any(strcmpi(method, ["auto", "fixed"]));
    end
    if ~ok
        error(message('MATLAB:parallel:parfor:InvalidRangePartitionMethod'));
    end
end
