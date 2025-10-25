classdef (Sealed) ExecutionContextWrapper < handle
    % This wrapper class facilitates the transition to using the ExecutionContext
    % and SymbolID when modular package feature is on by default.
    % It wraps a matlab.lang.internal.ExecutionContext object and provides a consistent
    % interface for resolving class names.
    % 
    % When matlab.lang.internal.ExecutionContext is available, it uses the resolveClass method
    % of the wrapped object. Otherwise, it returns a struct with field Name that has the input name.
    
    %   Copyright 2024 The MathWorks, Inc.
    
    % MCOS-8653

    properties(Constant)
        FundamentalClasses = dictionary(["double","single","int8","int16","int32","int64",...
            "uint8","uint16","uint32","uint64","logical","char","struct","cell","function_handle"], true);
    end

    properties
        Context % matlab.lang.internal.ExecutionContext {mustBeScalarOrEmpty}
    end
    
    methods
        function obj = ExecutionContextWrapper(context)
            arguments
                context = [] %matlab.lang.internal.ExecutionContext.empty
            end
            
            obj.Context = context;
        end
    end
    
    methods
        function symbol = resolveClass(contextWrapper, name)
            arguments
                contextWrapper (1,1) matlab.internal.validation.ExecutionContextWrapper
                name (1,1) string
            end
            import matlab.internal.validation.ExecutionContextWrapper

            context = contextWrapper.Context;
            if isempty(context)
                symbol = name;
            else
                if  ExecutionContextWrapper.FundamentalClasses.isKey(name)
                    symbol = classID(feval(name.append(".empty")));
                else
                    introContext = introspectionContext(context);
                    symbol = introContext.resolveClass(name);
                end
            end
        end
    end

    methods(Static)
        function tf = hasPackagesFeature()
            % for incremental submit.
            % Remove the following line and use feature("packages") when classID is available in MATLAB.
            %tf = false;

            tf = feature("packages");
        end
    end
end