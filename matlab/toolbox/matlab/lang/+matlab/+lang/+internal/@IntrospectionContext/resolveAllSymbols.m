%RESOLVEALLSYMBOLS  returns an array of matlab.lang.ResolvedSymbol objects where name
%   is found to be matching with given arguments `args`.
% 
%   - Input name can be a function name or a partial path to the function.
%   - Input args variable number of input arguments to the function name.
%   - Input MatchCase: a boolean indicating whether the search is performed
%          case-sensitively(true) or case-insensitively(false).
%   - IgnoreEmptyArgs: a boolean indicating whether the search will report all
%          methods if the given arguments `args` is empty.
%   - SearchOutOfContext: a boolean indicating whether the search will report
%          all the out-of-context result.
%
%   Copyright 2024 The MathWorks, Inc.

function out = resolveAllSymbols(context, name, args, opts)
    arguments (Input)
        context (1, 1) matlab.lang.internal.IntrospectionContext
        name (1, 1) string
    end
    arguments(Input, Repeating)
        args
    end
    arguments (Input)
        opts.MatchCase (1, 1) Bool = false
        opts.IgnoreEmptyArgs (1, 1) Bool = false
        opts.SearchOutOfContext (1, 1) Bool = false
    end
    arguments(Output)
        out (1, :) matlab.lang.internal.SymbolID
    end

    out = context.resolveAllSymbolsImpl(name, args{:}, opts);
end