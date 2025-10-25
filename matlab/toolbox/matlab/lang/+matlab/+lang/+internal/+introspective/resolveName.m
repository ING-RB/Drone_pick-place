function [resolvedName, malformed, foundParentFolder] = resolveName(topicInput, args)
    arguments
        topicInput                (1,1) string;
        args.QualifyingPath       (1,1) string  = "";
        args.JustChecking         (1,1) logical = true;
        args.FixTypos             (1,1) logical = false;
        args.ResolveOverqualified (1,1) logical = true;
        args.FindBuiltins         (1,1) logical = true;
        args.IntrospectiveContext (1,1) matlab.lang.internal.introspective.IntrospectiveContext = matlab.lang.internal.introspective.IntrospectiveContext;
    end

    args = namedargs2cell(args);
    nameResolver =  matlab.lang.internal.introspective.cache.lookup(@doResolveName, topicInput, args{:});

    resolvedName      = nameResolver.resolvedSymbol;
    malformed         = nameResolver.malformed;
    foundParentFolder = nameResolver.foundParentFolder;
end

function nameResolver = doResolveName(topicInput, varargin)
    arguments
        topicInput                (1,1) string;
    end
    arguments (Repeating)
        varargin;
    end
    nameResolver = matlab.lang.internal.introspective.NameResolver(topicInput, varargin{:});
    nameResolver.executeResolve();
end

%   Copyright 2014-2023 The MathWorks, Inc.
