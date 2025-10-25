function usage = getUsageFromDoc(functionName)
    %GETUSAGEFROMDOC Get usage syntax from documentation
    %   USAGE = GETUSAGEFROMDOC(FUNCTIONNAME) returns a string array of the
    %   syntaxes found for functionName. 
    %
    %   GETUSAGEFROMDOC attempts to get the syntax information from the 
    %   function reference page.
    %
    %   GETUSAGEFROMDOC will return syntaxes only for the first function 
    %   that WHICH finds. To get syntaxes for overloaded methods, provide
    %   the full classname and methodname to GETUSAGEFROMDOC.
    %
    %   Examples:
    %      usage = matlab.lang.internal.introspective.getUsageFromDoc("magic");
    %
    %         returns a string:
    %
    %           "M = magic(n)"
    %
    %      usage = matlab.lang.internal.introspective.getUsageFromDoc("LinearModel.Plot");
    %
    %         returns a 1x2 string array with:
    %
    %         usage(1) =
    %           "plot(mdl)"
    %
    %         usage(2) =
    %           "h = plot(mdl)"
    %
    %   See also DOC, GETUSAGE, GETUSAGEFROMHELP, GETUSAGEFROMSOURCE.
    
    %   Copyright 2017-2023 The MathWorks, Inc.
    
    functionName = convertStringsToChars(functionName);
    
    usage = strings(1,0);
    
    nameResolver = matlab.lang.internal.introspective.resolveName(functionName, "ResolveOverqualified", false);
    whichTopic = nameResolver.whichTopic;
    classInfo = nameResolver.classInfo;
    toolbox = matlab.lang.internal.introspective.getToolboxFolder(whichTopic, functionName);

    referenceHitIndex = matlab.lang.internal.introspective.getReferenceHitIndex(functionName, whichTopic, classInfo, toolbox);
    if ~isempty(referenceHitIndex.item) && ~referenceHitIndex.isParent
        usage = [referenceHitIndex.item.SyntaxGroups.Syntaxes];
    end
end
