function varargout = dotReference(obj, indexOp)
%
% Retrieves a value from the ElementSerializationContent
% Errors if the name does not exist
%

%   Copyright 2023-2024 The MathWorks, Inc.

    if (indexOp(1).Type == matlab.indexing.IndexingOperationType.Dot)
        file = matlab.lang.internal.introspective.IntrospectiveContext.caller.FullFileName;
        [~, func] = fileparts(file);
        caller = matlab.lang.internal.diagnostic.getStandardFunctionName(file, func);
        propName = indexOp(1).Name;
        if isscalar(indexOp)
            varargout = {obj.getValueWithCaller(propName, caller, file)};
        else
            val = obj.getValueWithCaller(propName, caller, file);
            varargout = {val.(indexOp(2:end))};
        end
    end
end
