classdef (Sealed) TableBuilder < matlab.io.internal.builders.Builder
%

%   Copyright 2019-2022 The MathWorks, Inc.

    methods
        function data = build(~, reader, data_untreated, omit_rows, omit_vars)
        % BUILD Constructs and returns a table based on the untreated data.

            types = reader.Options.fast_var_opts.Types(reader.SelectedIDs);
            types = types(:)';
            numextra = numel(data_untreated) - numel(types);
            types((numel(types) + 1):numel(data_untreated)) = {'char'};

            data = cell(size(data_untreated));

            % Skip type processing if data_untreated does not contain data. 
            if isempty(data_untreated) || isempty(data_untreated{1})
                data = data_untreated;
            else
                dates = strcmp(types, 'datetime');
                cats = strcmp(types, 'categorical');
                times = strcmp(types, 'duration');

                % Dates and Categoricals are imported in their final forms
                data(~(dates|cats|times)) = data_untreated(~(dates|cats|times));

                varopts = reader.Options.fast_var_opts.getVarOptsStruct(reader.SelectedIDs);
                for id = find(dates)
                    data{id} = matlab.io.internal.builders.Builder.processDates(data_untreated{id},...
                                                                      varopts{id}.DatetimeFormat, varopts{id}.InputFormat, varopts{id}.TimeZone);
                end
                for id = find(cats)
                    data{id} = matlab.io.internal.builders.Builder.processCats(data_untreated{id},...
                                                                      varopts{id}.Ordinal, varopts{id}.Protected);
                end
                for id = find(times)
                    data{id} = matlab.io.internal.builders.Builder.processTimes(data_untreated{id},...
                                                                      varopts{id}.DurationFormat, varopts{id}.InputFormat);
                end

                % If we receive a date column containing all NaTs, suggest that
                % they change the datetime variable InputFormat.
                for kk = find(dates(:)')
                    dateCols = data{kk};
                    if ~isempty(dateCols) && all(~isfinite(dateCols))
                        warning(message('MATLAB:readtable:AllNaTVariable'));
                        break;
                    end
                end
            end

            % Get methods reads the values if necessary
            varNames = reader.SelectedVariableNames;
            units = reader.VariableUnits;
            descr = reader.VariableDescriptions;

            [data,rowNames,rowDimName,varNames,units,descr] = ...
                matlab.io.internal.builders.TableBuilder.removeRowNamesFromVariables(...
                    reader.RowNamesID,data,varNames,units,descr,...
                    varNames,reader.RowNamesAsVariables);

            varNamesRead = reader.Options.VariableNamesLine > 0;
            allVarNames = reader.VariableNames;
            extraVarsRead = allVarNames(reader.NumVars+1:end);

            if numextra >= 0 && numextra < numel(extraVarsRead) ...
                    && (numel(data) == 0 || numel(data{end})==0)
                % There are only variable names to be added to the table.
                data(end + (1:numel(extraVarsRead))) = {cell(0,1)};
                varNames = allVarNames;
                numextra = 0;
            elseif varNamesRead && (numel(data) == 0 || numel(data{end})==0)
                % Due to input Range and detected metaRows, only selected
                % variable names are to be added to the table.
                data(end + 1:numel(varNames)) = {cell(0,1)};
            end

            [varNames, units, descr] = matlab.io.internal.builders.TableBuilder.handleExtraVariables(numextra,...
                                                              extraVarsRead, varNames, units, descr);

            dimNames = matlab.internal.tabular.private.metaDim().labels;
            if varNamesRead && reader.RowNamesID > 0 && ~isempty(rowDimName)
                dimNames{1} = rowDimName;
            end

            unknownNames = (strlength(varNames) == 0);
            varNames(unknownNames) = compose('Var%d', find(unknownNames));
            data = matlab.io.internal.functions.ReadTable.buildTableFromData(data,...
                                                              varNames(1:numel(data)),rowNames,dimNames, true, reader.RowNamesID > 0,...
                                                              reader.Options.PreserveVariableNames);

            % Set the metadata
            data.Properties.VariableUnits = units;
            if reader.Options.VariableDescriptionsLine > 0
                data.Properties.VariableDescriptions = descr;
            end

            % Remove omitted rows and vars
            data = matlab.io.internal.builders.Builder.removeOmittedRowsAndVars(data,....
                                                              omit_rows, omit_vars);
        end
    end

    methods(Static = true, Access = private)
        function [varNames, units, descr] = handleExtraVariables(numExtra, extraVarsRead, varNames, units, descr)
        % HANDLEEXTRAVARIABLES Uses the extra variable names that were read
        %   as the variable names for the extra columns of data. If none
        %   exist or more names are required, variable names of the form
        %   'ExtraVar%d' are added to varNames as well. Additionally, if
        %   variable units or descriptions were read, extra empty char
        %   arrays are appened to units or descr to account for the extra
        %   data.

            if numExtra > 0
                % Add Extra columns
                if ~isempty(extraVarsRead)
                    % Use the extra variable names read
                    lastIdx = min(numel(extraVarsRead), numExtra);
                    varNames = [varNames, extraVarsRead(1:lastIdx)];
                    numExtra = numExtra - lastIdx;
                end
                % If more variables are required
                if numExtra > 0
                    trailingnames = compose('ExtraVar%d',1:numExtra);
                    varNames = [varNames(:); matlab.lang.makeUniqueStrings(trailingnames(:),varNames,namelengthmax)]';
                end
                % add units, descr for extra variables
                if ~isempty(units), units((end+1):numel(varNames))={''}; end
                if ~isempty(descr), descr((end+1):numel(varNames))={''}; end
            end
        end

        function [data,rownames,rowDimName,names,units,descr] = removeRowNamesFromVariables(rowNamesID,data,names,units,descr,selected,rowNamesAsVariable)
            if (rowNamesID > 0)
                % Get the row names from the correct data column
                rownames = string(data{rowNamesID});
                emptyIDS = ~(strlength(rownames)>0);
                rownames(emptyIDS) = compose('Row%d',find(emptyIDS));
                rownames = matlab.lang.makeUniqueStrings(cellstr(rownames));
                rowDimName = selected{rowNamesID};
                if ~rowNamesAsVariable
                    % added the row names to the import variables, now take
                    % it out.
                    if ~isempty(units)
                        units(rowNamesID) = []; 
                    end
                    if ~isempty(descr)   
                        descr(rowNamesID) = []; 
                    end
                    names(rowNamesID) = [];
                    data(rowNamesID) = [];
                end
            else
                rowDimName = {};
                rownames = {};
            end
        end
    end
end
