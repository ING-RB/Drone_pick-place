%FROMSYMBOL Returns a scalar matlab.lang.internal.IntrospectionContext that
%   captures the context determined by the resolvedSymbol
%   Error condition: throws
%   SymbolDoesNotExist: if the resolvedSymbol does not exist in current MATLAB
%
%   Copyright 2024 The MathWorks, Inc.
function context = fromSymbol(resolvedSymbol)
    arguments(Input)
          resolvedSymbol (1, 1) matlab.lang.internal.ResolvedName
    end
    arguments(Output)
          context (1, 1) matlab.lang.internal.IntrospectionContext
    end
    context = matlab.lang.internal.IntrospectionContext.fromSymbolImpl(resolvedSymbol);
end