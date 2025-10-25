classdef (Abstract) TaskAction < matlab.mixin.Heterogeneous
    properties (SetAccess = protected)
        Name (1,1) string {mustBeNonmissing}
    end
    
    methods (Hidden, Abstract)
        evaluate(action, context, varargin)
        i = info(action)
    end

    methods (Static, Sealed, Access = protected)
        function action = convertObject(~, objectToConvert)
            action = matlab.buildtool.tasks.FunctionTaskAction(objectToConvert);
        end
    end
end

% Copyright 2021-2023 The MathWorks, Inc.
