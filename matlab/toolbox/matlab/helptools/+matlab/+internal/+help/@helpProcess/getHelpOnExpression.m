function getHelpOnExpression(hp, expression)
    lhs = "";
    assignBreak = regexp(expression, '^(?<lhs>(\([^\)]*\)|[^=])*+)=(?<rhs>.*)$', 'names');
    if ~isempty(assignBreak)
        lhs = assignBreak.lhs;
        expression = assignBreak.rhs;
    end
    
    functions = getIdentifiers(expression);
    variables = getIdentifiers(lhs);
    
    [variables, ~, i] = intersect([variables, functions], {hp.callerContext.WorkspaceVariables.name});
    types = {hp.callerContext.WorkspaceVariables(i).class};
    functions = setdiff(functions, {hp.callerContext.WorkspaceVariables.name});
    
    if hp.getHelpForTopics(functions)
        return;
    end
    
    operators = regexp(expression, '\.?[^\w\s."'']+', 'match');
    operators = unique(operators);
    if hp.getHelpForTopics(operators)
        return;
    end
    
    if isscalar(variables)
        hp.getHelpForTopics(variables);
    elseif ~isempty(variables)
        isaText = cellfun(@(x,y)matlab.internal.help.getInstanceIsa(x,y), variables, types, 'UniformOutput', false);
        padding = regexp(pad(variables, 'left'), '\s*', 'match', 'once', 'emptymatch');
        isaText = [padding; isaText];
        hp.helpStr = append(isaText{:});
    elseif isempty(functions) && isempty(operators)
        hp.getHelpForTopics("ans");
    end
end

function ids = getIdentifiers(expression)
    identifierPattern = lettersPattern(1) + alphanumericsPattern(0, inf);
    ids = extract(expression, identifierPattern + asManyOfPattern("." + identifierPattern))';
end

% Copyright 2018-2024 The MathWorks, Inc.
