classdef ReadMatrixWithImportOptions < matlab.io.internal.functions.ReadMatrixText ...
        & matlab.io.internal.functions.ReadMatrixSpreadsheet ...
        & matlab.io.internal.shared.GetExtensionsFromOpts
    %

    %   Copyright 2018-2022 The MathWorks, Inc.
    properties (Parameter)
        OutputType(1,1) string = "double";
    end

    properties
        ReadingLines(1,1) logical = false;
    end

    methods
        function [func,supplied,other] = validate(func,varargin)
            [func,varargin] = extractArg(func,"WebOptions",varargin, 2);

            [func,supplied,other] = validate@matlab.io.internal.functions.ExecutableFunction(func,varargin{:});
            matlab.io.internal.functions.parameter.assertNoRowNamesInputs(supplied);
            matlab.io.internal.functions.parameter.assertNoVariableNameInputs(supplied);
        end

        function func = set.OutputType(func,rhs)
            if strcmp(rhs,'logical')
                error(message('MATLAB:textio:io:UnsupportedConversionType','logical'))
            end
            func.OutputType = rhs;
        end

        function A = execute(func,supplied)
            vopts = func.Options.fast_var_opts;
            selection = func.Options.selectedIDs;

            for i = 1:length(selection)
                idx = selection(i);
                if any(fieldnames(vopts.OptionsStruct.Options{idx}) == "NumberSystem") && vopts.OptionsStruct.Options{idx}.NumberSystem ~= "decimal"
                    vopts = vopts.setVarOpts(idx, {'NumberSystem'}, {'decimal'});
                end
            end

            if vopts.numVars() == 0
                % Always add one variable to define the type.
                vopts = vopts.addVars(1,cellstr(func.OutputType));
                func.Options.AddedExtraVar = true;
            end
            if supplied.OutputType
                vopts = vopts.setTypes(selection, func.OutputType);
            end

            % Check that expected output is homogenous.
            numSelected = numel(selection);
            if numSelected > 1

                selectedTypes = vopts.Types(selection);
                if ~all(strcmp(selectedTypes(1),selectedTypes(2:end)))
                    error(message('MATLAB:textio:readmatrix:HeterogeneousData'));
                end

                if ~(vopts.isUniformOptions(selection))
                    warning(message('MATLAB:textio:readmatrix:DifferentVarOpts'))
                end
            end

            func.Options.fast_var_opts = vopts;
            if isa(func.Options,'matlab.io.text.TextImportOptions')
                A = func.execute@matlab.io.internal.functions.ReadMatrixText(supplied);
            else %isa(func.Options,'matlab.io.spreadsheet.SpreadsheetImportOptions')
                A = func.execute@matlab.io.internal.functions.ReadMatrixSpreadsheet(supplied);
            end

            if isempty(A)
                if func.Options.AddedExtraVar
                    outputSize = [0, 0];
                else
                    outputSize = [0, numel(func.Options.SelectedVariableNames)];
                end
                switch func.OutputType
                    case 'string'
                        A = string.empty(outputSize);
                    case 'char'
                        A = cell.empty(outputSize);
                    case 'datetime'
                        A = datetime.empty(outputSize);
                    case 'duration'
                        A = duration.empty(outputSize);
                    case 'categorical'
                        A = categorical.empty(outputSize);
                    otherwise
                        A = reshape(A,outputSize);
                        if supplied.OutputType
                            A = cast(A,func.OutputType);
                        end
                end
            end
        end
    end

end
