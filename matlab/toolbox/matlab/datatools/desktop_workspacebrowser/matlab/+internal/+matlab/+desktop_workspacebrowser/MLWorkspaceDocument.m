classdef MLWorkspaceDocument < internal.matlab.variableeditor.MLDocument
    %MLWorkspaceDocument
    %   MATLAB Workspace Document

    % Copyright 2013-2024 The MathWorks, Inc.

    methods
        function this = MLWorkspaceDocument(manager, variable, workspaceArgs)
            arguments
                manager
                variable
                workspaceArgs.UserContext char = '';
                workspaceArgs.DisplayFormat char = '';
            end
            args = namedargs2cell(workspaceArgs);
            this@internal.matlab.variableeditor.MLDocument(manager, variable, args{:});
        end

        function data = variableChanged(this, varargin)
            % This function needs to be overwritten, otherwise the superclass
            % version may try to swap out views based on the variable data,
            % whereas the Workspace Browser always keeps the same
            % ViewModel/DataModel.
            data = this.DataModel.Data;
        end
    end
end
