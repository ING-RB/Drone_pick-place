function lastCommand = getLastCommandForHelp(commands)
    lastCommand = "";
    for command = fliplr(commands)
        modifiedCommand = purgeText(command);
        modifiedCommand = removeCommandArguments(modifiedCommand);

        if isempty(regexp(modifiedCommand, '\<(help|doc)\>', 'once'))
            lastCommand = sanitizeCommand(modifiedCommand);
            return;
        end
    end
end

function command = purgeText(command)
    % purge text literals
    command = regexprep(command, '([''"]).*?\1', '$1$1');
    % purge comments
    command = regexprep(command, "%.*$", "");
end

function command = removeCommandArguments(command)
    tree = mtree(command);
    dual = mtfind(tree, 'Kind', 'DCALL');
    if ~isempty(dual)
        args = dual.Right.List;
        command = string(tree2str(tree, {args, ''}));
    end
end

function command = sanitizeCommand(command)
    command = replace(command, ["&lt;", "&gt;", "&amp;"], ["<", ">", "&"]);
end

% Copyright 2018-2020 The MathWorks, Inc.
