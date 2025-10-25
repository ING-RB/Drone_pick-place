function obj = dotAssign(obj, indexOp, varargin)
%
% Updates an existing name/value on the ElementSerializationContent
%

%   Copyright 2023-2024 The MathWorks, Inc.
    
    if (indexOp(1).Type == matlab.indexing.IndexingOperationType.Dot)
        file = matlab.lang.internal.introspective.IntrospectiveContext.caller.FullFileName;
        [~, func] = fileparts(file);
        caller = matlab.lang.internal.diagnostic.getStandardFunctionName(file, func);
        propName = indexOp(1).Name;
        if isscalar(indexOp)
            obj.updateValueWithCaller(propName, caller, file, varargin{:});
        else
            val = obj.getValueWithCaller(propName, caller, file);
            [val.(indexOp(2:end))] = varargin{:};
            obj.updateValueWithCaller(propName, caller, file, val);
        end
    end
end
