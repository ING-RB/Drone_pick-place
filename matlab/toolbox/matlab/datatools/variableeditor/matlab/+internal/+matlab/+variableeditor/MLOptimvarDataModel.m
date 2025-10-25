classdef MLOptimvarDataModel < ...
        internal.matlab.variableeditor.MLArrayDataModel & ...
        internal.matlab.variableeditor.OptimvarDataModel
    %MLOBJECTARRAYDATAMODEL
    % MATLAB Object Array Data Model

    % Copyright 2022 The MathWorks, Inc.

    methods
        % Constructor
        function this = MLOptimvarDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLArrayDataModel(...
                name, workspace);
        end

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
            setStrings = this.setData@internal.matlab.variableeditor.OptimvarDataModel(c{:});
            setCmd = this.setCommand(setStrings, errorMsg);
            if ~isempty(setCmd)
                varargout{1} = setCmd;
            end
        end
    end
    
    methods (Access = protected)
        function [I,J] = doCompare(this, newData)
            [I,J] = find(arrayfun(@(a,b) ~isequal(a,b), ...
                this.Data, newData));
        end

        function codeToExecute = assignNameToCommand(this, setCommand)
             codeToExecute = setCommand;
        end
    end
end
