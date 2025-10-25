% This class is unsupported and might change or be removed without notice in
% future version.

% This class provides functionality for importing from a workspace.

% Copyright 2020-2022 The MathWorks, Inc.

classdef WorkspaceProvider < matlab.internal.importdata.ImportVarSelectionProvider & matlab.internal.importdata.FilterableProvider

    properties
        % The workspace to query variables from
        Workspace string = "base";
    end

    methods
        function this = WorkspaceProvider(filename)
            % Create an instance of an WorkspaceProvider

            arguments
                filename (1,1) string
            end

            this = this@matlab.internal.importdata.ImportVarSelectionProvider(filename);
            this.Workspace = filename;

            % FileName is unused for this ImportProvider instance, it just needs
            % to be unique.
            this.Filename = "Variable";

            % This is used for the preference setting.  Unused in this instance,
            % but should be unique.
            this.FileType = "workspace";
        end

        function code = getImportCode(~)
            % There's no code for the import, it is just the variables which are
            % returned
            code = "";
        end

        function [varNames, vars] = getVariables(this)
            % Called to get the variables to display.  Overrides the base class
            % because this queries a workspace directly, instead of getting the
            % variables from some other import function (like imread, audioread,
            % etc.)

            arguments
                this matlab.internal.importdata.WorkspaceProvider
            end

            varNames = evalin(this.Workspace, "who");
            vars = {};
            origVarNames = varNames;
            varNames = string(varNames);
            if iscell(this.FilterFunction)
                filterFuncs = this.FilterFunction;
            else
                filterFuncs = {this.FilterFunction};
            end

            for idx = 1:length(origVarNames)
                try
                    varName = origVarNames{idx};

                    % Get the variable from the workspace
                    var = evalin(this.Workspace, varName);

                    addVar = this.isValidForFilter(var, filterFuncs);
                catch
                    % There was a filter function, where the variable failed to
                    % meet the criteria.
                    addVar = false;
                end

                if addVar
                    % If we've reached this line, then either there was no
                    % filter function, or the variable passes the filter
                    % function's criteria
                    vars{end+1} = var; %#ok<AGROW>
                else
                    varNames(varNames == varName) = [];
                end
            end
        end

        function s = getTaskSummary(~)
            s = "";
        end

        function s = getSupportedFileExtensions(~)
            s = "";
        end
    end
end
