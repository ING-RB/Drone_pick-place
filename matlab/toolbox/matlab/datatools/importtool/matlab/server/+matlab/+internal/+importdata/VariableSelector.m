% This class is unsupported and might change or be removed without
% notice in a future version.

% This class extends the DataImporter to provide a mechanism to select variables to import from a workspace.  For example:
%
%     %Create a provider
%     wp = matlab.internal.importdata.WorkspaceProvider("base");
%
%     %Set the filter function if desired
%     wp.FilterFunction = @(x) mustBeA(x, ["table", "timetable"]);
%
%     %Create a VariableSelector, providing the provider, and import
%     v = matlab.internal.importdata.VariableSelector(wp);
%     selectedVarNames = v.import();

% Copyright 2020-2023 The MathWorks, Inc.
classdef VariableSelector < matlab.internal.importdata.DataImporter
    properties
        % The variable names selected by the user
        SelectedVariableNames string = strings(0);
    end
    
    methods
        function this = VariableSelector(provider)
            % Create an instance of the VariableSelector

            arguments
                provider (1,1) matlab.internal.importdata.ImportProvider
            end
            
            this@matlab.internal.importdata.DataImporter(provider);
            
            % Setup some properties for the variable selector usage
            this.SelectAllAtStartup = false;
            this.DisableImportBtnAtStartup = true;
        end
    end
    
    methods(Access = protected)
        function importData(this, ~, selectedVarNames)
            % Called when the user clicks the Import button.  Set the selected
            % variable names property, and return it in the ImportData if we're
            % doing synchronous import.
            
            arguments
                this (1,1) matlab.internal.importdata.VariableSelector
                ~
                selectedVarNames string
            end

            this.SelectedVariableNames = selectedVarNames;
            if this.SynchronousImport
                this.ImportedData = selectedVarNames;
            end
            this.ImportDone = true;
        end
    end
end
