function saveImpl(file, opts, names, values)
    arguments
        file {mustBeTextScalar} %#ok<*INUSA>
        opts {mustBeA(opts, 'cell')}
    end
    arguments (Repeating)
        names {mustBeTextScalar}
        values
    end
    namesAndValues = [names; values]; %#ok<*NASGU>
    % Copy all variables into a struct since assignAll may overwrite them
    %   with user variables to save.
    for varHere = whos'
        var = varHere.name;
        hopefullyNoOneWouldUseThisNameForTheirOwnVar.(var) = eval(var);
    end
    assert(all(names ~= "hopefullyNoOneWouldUseThisNameForTheirOwnVar"), 'Coder:builtins:SaveSpecialVarName', message('Coder:builtins:SaveSpecialVarName', 'hopefullyNoOneWouldUseThisNameForTheirOwnVar').getString);
    assignAll(hopefullyNoOneWouldUseThisNameForTheirOwnVar.namesAndValues{:});
    try
        save(hopefullyNoOneWouldUseThisNameForTheirOwnVar.file, ...
             hopefullyNoOneWouldUseThisNameForTheirOwnVar.names{:}, ...
             hopefullyNoOneWouldUseThisNameForTheirOwnVar.opts{:});
    catch ex
        throwAsCaller(ex);
    end
end

function assignAll(names, values)
    arguments (Repeating)
        names {mustBeTextScalar}
        values
    end
    for i = 1:numel(names)
        assignin('caller', names{i}, values{i});
    end
end
