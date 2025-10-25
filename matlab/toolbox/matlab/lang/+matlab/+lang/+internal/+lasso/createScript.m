function outScript = createScript(args)
    arguments
        args.History    (1,1) matlab.lang.internal.history.CommandHistory = matlab.lang.internal.history.CommandHistory.create;
        args.Timestamp  (1,1) datetime = NaT;
        args.Variables  (1,:) string {mustBeVarnames} = [];
        args.Statements (1,:) {mustBeInteger, mustBePositive} = [];
    end
    
    findingTimestamp = ~ismissing(args.Timestamp);
    findingVariables = ~isempty(args.Variables);
    findingStatements = ~isempty(args.Statements);
    
    script = strings(0);
    
    if findingTimestamp
        sessions = args.History.getSessionByTimestamp(args.Timestamp);
    elseif findingVariables && ~findingStatements
        sessions = args.History.getSessions(2); % maybe a different heuristic here?
        sessions(~sessions.containsVariable(args.Variables)) = [];
        if isempty(sessions)
            error(message('MATLAB:internal:lasso:VariableNotFound', args.Variables(1)));
        end
    else
        sessions = args.History.getSessions(1);
    end

    ex = [];
    for session = sessions
        try
            [scriptLines, lineNos, lastLine] = session.convertToScript;
            script = matlab.lang.internal.lasso.minimizeScript(scriptLines, args.Variables, args.Statements, lastLine, lineNos); 
            break;
        catch ex
        end
    end
    if isempty(script)
        assert(~isempty(ex));
        throw(ex);
    end

    script = join(script, newline);
    
    if ~nargout && matlab.desktop.editor.isEditorAvailable
        matlab.desktop.editor.newDocument(char(script));
    else
        outScript = script;        
    end
end

function mustBeVarnames(variables)
    for variable = variables
        if ~isvarname(variable)
            error(message('MATLAB:codetools:InvalidVariableName', variable));
        end
    end
end

%   Copyright 2019-2023 The MathWorks, Inc.
