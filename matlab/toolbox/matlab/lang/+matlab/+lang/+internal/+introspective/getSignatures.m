function signatures = getSignatures(functionName)
    %GETSIGNATURES Get signatures from documentation or source code
    %   USAGE = GETSIGNATURES(FUNCTIONNAME) returns a string array of the
    %   signatures found for functionName.
    %
    %   GETSIGNATURES attempts to get the syntax information from the function
    %   reference page. If there is no GETSIGNATURES reference page, or if the page
    %   does not contain any syntaxes, GETUSAGE will then attempt to get the
    %   syntaxes from the MATLAB file help text.
    %
    %   GETSIGNATURES will return syntaxes only for the first function that WHICH
    %   finds. To get syntaxes for overloaded methods, provide the full
    %   classname and methodname to GETSIGNATURES.
    %
    %   Examples:
    %      signatures = matlab.lang.internal.introspective.getSignatures("magic");
    %
    %         returns a string:
    %
    %           "M = magic(n)"
    %
    %      signatures = matlab.lang.internal.introspective.getSignatures("LinearModel.Plot");
    %
    %         returns a 1x3 string array with:
    %
    %         signatures(1) =
    %           "plot(mdl)"
    %
    %         signatures(2) =
    %           "plot(ax,mdl)"
    %
    %         signatures(3) =
    %           "h = plot(___)"
    %
    %   See also HELP, DOC, GETUSAGE.

    cleanup.cache = matlab.lang.internal.introspective.cache.enable; %#ok<STRNU>

    signatures = matlab.lang.internal.introspective.getUsageFromDoc(functionName);

    if isempty(signatures)
        signatures = matlab.lang.internal.introspective.getUsageFromHelp(functionName);
    end

    if isempty(signatures)
        nameResolver = matlab.lang.internal.introspective.resolveName(functionName, ResolveOverqualified=false);
        if nameResolver.isResolved
            signatures = matlab.lang.internal.introspective.getUsageFromSource(nameResolver.whichTopic, nameResolver.resolvedTopic);
        end
    end
end

%   Copyright 2024 The MathWorks, Inc.
