classdef ReadTimeTable < matlab.io.internal.functions.DetectImportOptions ...
        & matlab.io.internal.functions.ReadTimeTableWithImportOptions ...
        & matlab.io.internal.functions.HasAliases
    %
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    methods (Access = protected)
        function [rhs,obj] = setSheet(obj,rhs)
            [rhs,obj] = obj.setSheet@matlab.io.internal.functions.DetectImportOptions(rhs);
        end
        
        function val = getSheet(obj,val)
            val = obj.getSheet@matlab.io.internal.functions.DetectImportOptions(val);
        end
    end
    
    methods
        function names = usingRequired(~)
            names = "Filename";
        end
        
        function v = getAliases(func)
            v = [func.getAliases@matlab.io.internal.functions.DetectImportOptions(),...
                func.getAliases@matlab.io.internal.functions.ReadTableWithImportOptions(),...
                matlab.io.internal.functions.ParameterAlias("SampleRate","SamplingRate")];
        end
        
        function tt = execute(func,supplied)
            
            % With properties all validated, any shared properties don't need to be re-validated.
            % execute calls are written to accept pre-validated inputs
            func.DetectHeader = true;
            func.EmptyColumnType = 'double';
            func.Options = func.execute@matlab.io.internal.functions.DetectImportOptions(supplied);
            vopts = func.Options.fast_var_opts;
            names = vopts.OptionsStruct.Names;

            generatedNames = find(~(strlength(names)>0));
            selectedIdx = func.Options.selectedIDs;
            needVarName = intersect(generatedNames,selectedIdx);
            
            if supplied.RowTimes && isnumeric(func.RowTimes)
                timeIdx = func.RowTimes;
            elseif ~supplied.RowTimes && ~(supplied.TimeStep || supplied.SampleRate)
                % Nothing Supplied, detecting from the data
                types = func.Options.fast_var_opts.Types;
                timeIdx = max([0 find(types == "datetime" | types=="duration",1)]);
            elseif supplied.RowTimes && ischar(func.RowTimes)
                % RowTimes Supplied By Name
                timeIdx = max([0 find(strcmp(func.RowTimes,vopts.Names))]);
                if timeIdx > 0 && any(generatedNames==timeIdx)
                    func.RowTimes = 'Time';
                end
            else
                timeIdx = 0;
            end
            
            if ~isempty(needVarName)
                % Compute unselected indexes
                unselectedIdx = ones(max(selectedIdx), 1);
                unselectedIdx(selectedIdx) = 0;
                names(unselectedIdx == 1) = {''};
                
                % Variable position with respect to the names array
                varNamesIdx = selectedIdx;
                
                % Subtract variable index for variables appearing after the
                % time vector
                indexesAfterTime = zeros(size(needVarName));
                if timeIdx > 0
                    % If the time column does not have a variable name, do not
                    % generate one, as 'Time' is used by default.
                    if isempty(names{timeIdx})
                        names{timeIdx} = 'Time';
                        indexesAfterTime(needVarName==timeIdx) = [];
                        needVarName(needVarName==timeIdx) = [];
                    end
                    
                    indexesAfterTime(needVarName > timeIdx) = 1;
                    unselectedIdx(timeIdx) = 0;
                    varNamesIdx(varNamesIdx == timeIdx) = [];
                end
                
                % varNums holds the number used to generate the variable
                % names
                varNums = needVarName - indexesAfterTime;
                
                % Subtract variable name value for unselected variables
                cumsumUnselected = cumsum(unselectedIdx);
                varNums = varNums - cumsumUnselected(varNums);
                
                % Generate variable names and assign to 'names' vector
                generatedNames = compose('Var%d', varNums);
                names(needVarName) = generatedNames;
                
                % Set variable names in case the selected RowTimes is a
                % generated value. 
                vopts = vopts.setVarNames(1:numel(names), names(:));
                func.Options.fast_var_opts = vopts;
                tt = func.execute@matlab.io.internal.functions.ReadTimeTableWithImportOptions(supplied);
                
                % Need to set the time dimension name and variable names
                % again, matlab.io.spreadsheet.internal.readSpreadsheet can
                % overwrite generated variable names.
                % Set time dimension name
                if timeIdx > 0
                    tt.Properties.DimensionNames(1) = names(timeIdx);
                end
                
                % Set variable names
                if numel(tt.Properties.VariableNames) > 0
                    tt.Properties.VariableNames = names(varNamesIdx);
                end
            else       
                tt = func.execute@matlab.io.internal.functions.ReadTimeTableWithImportOptions(supplied);
            end
        end
        
        function exts = getExtensions(obj)
            exts = obj.getExtensions@matlab.io.internal.functions.DetectImportOptions();
        end
        
        function [func,supplied,other] = validate(func,varargin)
            [func,supplied,other] = validate@matlab.io.internal.functions.DetectImportOptions(func,varargin{:});
        end
    end
end
