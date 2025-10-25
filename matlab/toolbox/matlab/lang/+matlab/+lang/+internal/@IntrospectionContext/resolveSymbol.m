%RESOLVESYMBOL  returns a scalar matlab.lang.internal.ResolvedSymbol object 
%    when the symbol is found to be the best matching result with given 
%    arguments `args`. Otherwise returns missing.
%
%    name must be the function name and the result is guaranteed to be case sensitive 
%    match args variable number of input arguments to the function name.
%
%   Copyright 2024 The MathWorks, Inc.

function out = resolveSymbol(context, name, args)
    arguments(Input)
        context (1, 1) matlab.lang.internal.IntrospectionContext
        name (1, 1) string
    end
    arguments(Input, Repeating)
        args
    end
    arguments(Output)
         out matlab.lang.internal.SymbolID {mustBeScalarOrEmpty}
    end

    out = resolveSymbolImpl(context, name, args{:});
end