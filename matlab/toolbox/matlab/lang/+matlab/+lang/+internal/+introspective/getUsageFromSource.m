function usage = getUsageFromSource(fullPath, name)
    %GETUSAGEFROMSOURCE Get usage syntax from source code.
    %   USAGE = GETUSAGEFROMSOURCE(FULLPATH, NAME) returns a string
    %   containing the function line for the local function NAME found in
    %   the source file FULLPATH.
    %
    %   See also HELP, GETUSAGE, GETUSAGEFROMDOC, GETUSAGEFROMHELP.
    
    %   Copyright 2017-2023 The MathWorks, Inc.
    
    fullPath = convertStringsToChars(fullPath);
    name = convertStringsToChars(name);
    
    usage = strings(1,0);
    whichTopic = regexprep(fullPath, '\.p$', '.m');
    existence = exist(whichTopic, 'file');
    if existence == 2
        try
            functionText = matlab.internal.getCode(whichTopic);
        catch
            functionText = fileread(whichTopic);
        end
        functionText = matlab.lang.internal.introspective.stripLineContinuations(functionText);
        functionName = regexp(name, '\w+$', 'match', 'once');
        [functionNames, functionSplit] = matlab.lang.internal.introspective.getFunctionLine(string(functionText), functionName, true);
        if ~isempty(functionNames) && (functionName ~= "" || isempty(regexp(functionSplit{1}, '\S', 'once')))
            if name ~= "" && ~contains(name, "/")
                % name was resolved, but is not a method
                functionName = name;
            else
                functionName = functionNames.functionName;
            end
            usage = functionNames.lhs + functionName + functionNames.rhs;
            % insert optional missing commas between outputs
            usage = regexprep(usage, '(\w)\s+(?=\w)', '$1,');
            % remove all whitespace
            usage = regexprep(usage, '\s+', '');
            % remove empty brackets/parens
            usage = replace(usage, ["()", "[]="], '');
            % insert whitespace back after commas and around equals
            usage = replace(usage, [",", "="], [", ", " = "]);
        elseif matlab.lang.internal.introspective.isClassMFile(whichTopic)
            % class with no constructor
            if contains(name, "/") % explicit constructor
                name = extractBefore(name, "/");
            end
            usage = "obj = " + name;
        elseif name ~= ""
            % script
            usage = string(name);
        end
    end
end
