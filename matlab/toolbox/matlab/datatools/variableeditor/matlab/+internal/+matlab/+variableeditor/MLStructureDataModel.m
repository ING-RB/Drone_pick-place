classdef MLStructureDataModel < internal.matlab.variableeditor.MLArrayDataModel & internal.matlab.variableeditor.StructureDataModel
    %MLSTRUCTUREDATAMODEL
    %   MATLAB Structure Data Model
    
    % Copyright 2013-2021 The MathWorks, Inc.
       
    methods(Access='public')
        % Constructor
        function this = MLStructureDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLArrayDataModel(...
                name, workspace);
            this.Name = name;
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
            setStrings = this.setData@internal.matlab.variableeditor.StructureDataModel(c{:});
            setCmd = this.setCommand(setStrings, errorMsg);
            if ~isempty(setCmd)
                varargout{1} = setCmd;
            end            
        end
        
        function varargout = getData(this, varargin)
            if nargin>=3 && ~isempty(this.Data)
                fieldNames = fieldnames(this.Data);
                % Fetch a block of data using startRow and endRow.  The
                % columns are not used, because scalar structs always
                % display a fixed number of columns.
                startRow = min(max(1,varargin{1}),size(fieldNames,1));
                endRow = min(max(1,varargin{2}),size(fieldNames,1));
                
                % Since we can't subreference specific fields of a
                % structure as a structure, we'll convert to cell arrays,
                % to do the sub-referencing.
                values = struct2cell(this.Data);
                
                varargout{1} = values{startRow:endRow};
            else
                % Otherwise return all data
                varargout{1} = this.Data;
            end
        end

        % updateData
        function data = updateData(this, varargin)
            newData = varargin{1};
            origData = this.Data;
            classes = cellfun(@(a) class(a), struct2cell(origData), 'UniformOutput', false);
            newClasses = cellfun(@(a) class(a), struct2cell(newData), 'UniformOutput', false);

            % Check for type changes on structure elements structure elements
            if ~isequaln(classes,newClasses)
                sameSize = numel(classes) == numel(newClasses);
                eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
                if ~sameSize
                    % Keep [I, J] consistent with the value returned in
                    % doCompare, when the number of fields in the struct
                    % has changed.
                    [I,J] = meshgrid(1:size(newClasses,1),1:4);
                    eventdata.SizeChanged = true;
                else
                    %  name/value/class could have changed, update I,J accordingly
                    [I,J] = this.doCompare(newData);
                end                
                I = I(:)';
                J = J(:)';
                % TODO: The results of the comparison/meshgrid are currently not
                % being used.  Need to add the logic back in to update a single
                % cell on the client if only a single cell has changed.(Otherwise
                % the entire viewport will be updated)
                
                % Set the new data
                this.Data = newData;

                % The eventData Values property should represent the data
                % that has changed within the cached this.Data block as it
                % is rendered. Currently the cached data may be huge, so
                % for now don't attempt to represent it.
                
                this.notify('DataChange',eventdata);
                
                data = this.Data;
                return;
            end
            
            % Otherwise use the superclass updateData method
            data = this.updateData@internal.matlab.variableeditor.MLArrayDataModel(varargin{:});
        end
    end %methods
    
    methods(Access='protected')
        function [I,J] = doCompare(this, newData)
            origData = this.Data;
            fieldNames = fieldnames(origData);
            newFieldNames = fieldnames(newData);
            try
                if length(fieldNames) == length(newFieldNames)
                    % Create cell arrays containing the variable info to
                    % compare from origData and newData, for example:
                    % {'A', A, 'double', [1,1];
                    %  'B', B, 'table', [100,5]}
                    origDataCell = cell(length(fieldNames), 4);
                    newDataCell = cell(length(fieldNames), 4);
                    for idx = 1:length(fieldNames)
                        f = fieldNames{idx};
                        val = origData.(f);
                        origDataCell{idx, 1} = f;
                        origDataCell{idx, 2} = val;
                        origDataCell{idx, 3} = class(val);
                        if istall(val)
                            origDataCell{idx, 4} = sizeAsString(val);
                        else
                            origDataCell{idx, 4} = size(val);
                        end

                        f = newFieldNames{idx};
                        val = newData.(f);
                        newDataCell{idx, 1} = f;
                        newDataCell{idx, 2} = val;
                        newDataCell{idx, 3} = class(val);
                        if istall(val)
                            newDataCell{idx, 4} = sizeAsString(val);
                        else
                            newDataCell{idx, 4} = size(val);
                        end
                    end

                    % If the length of the fieldnames is the same, compare the
                    % field names, values, classes and sizes of the original struct to the
                    % newData struct. If isequal throws an error, the field
                    % should be changed.
                    [I,~] = find(cellfun(@(a,b) ~internal.matlab.variableeditor.areVariablesEqual(a,b), ...
                        origDataCell, newDataCell, ...
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

        function lhs=getLHS(this, idx)
            % Return the left-hand side of an expression to assign a value
            % to a matlab structure field.  (The variable name will be
            % pre-pended by the caller).  Returns a string like: '.field'
            fieldNames = fieldnames(this.Data);
            numericIdx = str2num(idx); %#ok<ST2NM>
            lhs = [ '.' fieldNames{numericIdx(1)} ];
        end
    end
end
