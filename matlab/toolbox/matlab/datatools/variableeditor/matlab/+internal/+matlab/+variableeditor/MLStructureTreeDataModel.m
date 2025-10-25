classdef MLStructureTreeDataModel < internal.matlab.variableeditor.MLStructureDataModel & internal.matlab.variableeditor.StructureTreeDataModel
    %MLSTRUCTUREDATAMODEL
    %   MATLAB MLStructureTreeDataModel
    
    % Copyright 2022-2025 The MathWorks, Inc.
       
    methods(Access='public')
        % Constructor
        function this = MLStructureTreeDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLStructureDataModel(...
                name, workspace);
            % The tree Data Model may have period delimiters; they would not play nice with our custom
            % delimiters (see g3128711). We force it to use a custom delimiter.
            this.Name = char(internal.matlab.variableeditor.VEUtils.getCustomDelimitedRowIdVersion(name));
        end
        
        % setData
        % Sets a block of values.
        % If only one paramter is specified that parameter is assumed to be
        % the data and all of the data is replaced by that value.
        % If three paramters are passed in the the first value is assumed
        % to be the data and the second is the row and third the column.
        % Otherwise users can specify value index pairings in the form
        % setData('value', index1, 'value2', index2, ...)
        %
        %  The return values from this method are the formatted command
        %  string to be executed to make the change in the variable.
        function varargout = setData(this,varargin)
            [errorMsg, c] = this.getSetDataParams(varargin);
            setStrings = this.setData@internal.matlab.variableeditor.StructureTreeDataModel(c{:});
            setCmd = this.setCommand(setStrings, errorMsg);
            if ~isempty(setCmd)
                varargout{1} = setCmd;
            end            
        end
    end %methods
    
    methods(Access='protected')
        function [I,J] = doCompare(this, newData)
            origData = this.Data;
            fieldNames = fieldnames(origData);
            newFieldNames = fieldnames(newData);            
            try
                if length(fieldNames)==length(newFieldNames)
                    origDataStruct = struct2cell(origData);
                    newDataStruct = struct2cell(newData);
                    classesAndSizes = cellfun(@(a) {class(a) size(a)}, origDataStruct, 'UniformOutput', false);
                    newClassesAndSizes = cellfun(@(a) {class(a) size(a)}, newDataStruct, 'UniformOutput', false);
                    % If the length of the fieldnames is the same, compare the
                    % field names, values, classes and sizes of the original struct to the
                    % newData struct. If isequal throws an error, the field
                    % should be changed.
                    [I,~] = find(cellfun(@(a,b) ~internal.matlab.variableeditor.areVariablesEqual(a,b), ...
                        [fieldNames origDataStruct vertcat(classesAndSizes{:})],...
                        [newFieldNames newDataStruct vertcat(newClassesAndSizes{:}) ], ...
                        'ErrorHandler', @(err, a, b) true));
                    
                    % if J is other than fieldColumnIndex, cause J to update
                    % all column fields as other stat columns could be affected.
                    [I,J] = meshgrid(I, 1: this.NumberOfColumns);
                else
                    % Otherwise, the number of fields has changed, so return
                    % I,J where the size is not 1,1.  This is to prevent the
                    % MLArrayDataModel from sending a DataChange event with a
                    % single value.
                    [I,J] = meshgrid(1:size(newFieldNames,1),1:this.NumberOfColumns);
                end
            catch
                % Ignore any errors, just assume it changed
                [I,J] = meshgrid(1:size(newFieldNames,1),1:4);
            end
        end

        % Return the left-hand side of an expression to assign a value
        % to a matlab structure field (the variable name will be
        % prepended by the caller).
        function lhs=getLHS(this, rowID, getExecutableIDForm)
            arguments
                this
                rowID (1,1) string
                getExecutableIDForm (1,1) logical = true;
            end

            dataModelName = this.Name;

            % If "rowID" is not properly period-delimited, we must make it so.
            % We must also ensure the Data Model name is period-delimited in this case,
            % otherwise, we may get a mixture of period-delimited and custom-delimited names.
            if getExecutableIDForm
                rowID = internal.matlab.variableeditor.VEUtils.getExecutableRowIdVersion(rowID);
                dataModelName = internal.matlab.variableeditor.VEUtils.getPeriodDelimitedRowIds(dataModelName);
            end

            lhs = extractAfter(rowID, dataModelName);
        end

        function codeToExecute = assignNameToCommand(this, setCommand)
            % "this.Name" may have custom delimiters. We want to convert them back
            % to periods so we generate valid code.
            executableName = internal.matlab.variableeditor.VEUtils.getPeriodDelimitedRowIds(this.Name);
            codeToExecute = sprintf('%s%s', executableName, setCommand);
        end
    end
end
