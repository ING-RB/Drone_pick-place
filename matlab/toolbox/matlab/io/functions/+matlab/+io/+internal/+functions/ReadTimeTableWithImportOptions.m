classdef ReadTimeTableWithImportOptions < matlab.io.internal.functions.ReadTableWithImportOptions ...
        & matlab.io.internal.functions.Table2Timetable ... 
        & matlab.io.internal.functions.HasAliases
    %

    %   Copyright 2018-2020 The MathWorks, Inc.

    methods

        function v = getAliases(func)
            v = [func.getAliases@matlab.io.internal.functions.ReadTableWithImportOptions(),...
                 func.getAliases@matlab.io.internal.functions.Table2Timetable()];
        end

        function tt = execute(func,supplied)
            persistent t2ttProps
            if isempty(t2ttProps)
                t2ttProps = string(properties('matlab.io.internal.functions.Table2Timetable')');
                t2ttProps(t2ttProps=="Aliases") = [];
            end
            
            matlab.io.internal.functions.parameter.assertNoRowNamesInputs(supplied);
            
            suppliedTimeParam = supplied.RowTimes || supplied.TimeStep || supplied.SampleRate;
            if ~any(strcmp(func.Options.VariableTypes,'duration')) && ...
                    ~any(strcmp(func.Options.VariableTypes,'datetime')) && ~suppliedTimeParam
                error(message("MATLAB:readtable:NoTimeVarFound"));
            end

            % With properties all validated, any shared properties don't need to be re-validated.
            % execute calls are written to accept pre-validated inputs
            t = func.execute@matlab.io.internal.functions.ReadTableWithImportOptions(supplied);

            args = {};
            for p = t2ttProps
                if supplied.(p)
                    args(end+1:end+2) = {p,func.(p)};
                end
            end

            tt = table2timetable(t,args{:});
        end
    end
end
    