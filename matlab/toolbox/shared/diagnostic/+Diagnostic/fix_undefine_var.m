function success = fix_undefine_var(ws, model, varname, varvalue)
    if isequal(ws, 'base')
        assignin('base', varname, evalin('base', varvalue));
    else
        ws = get_param(model, 'modelworkspace');
        ws.assignin(varname, evalin('base', varvalue));
    end
   success = message('SLDD:sldd:VariableCreated', varname).getString;
end

