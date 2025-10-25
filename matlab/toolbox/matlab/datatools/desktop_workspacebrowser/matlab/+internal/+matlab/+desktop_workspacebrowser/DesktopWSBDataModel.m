classdef DesktopWSBDataModel < internal.matlab.variableeditor.DataModel

    % DataModel for the Desktop Workspace Browser

    % Copyright 2024-2025 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Workspace (1,1) string = "debug";
        CodePublishingDataModelChannel (1,1) string = "WorkspaceBrowser/who";
    end

    properties(Dependent, SetAccess=immutable)
        Data
    end

    methods
        function val = get.Data(this)
            val = this.getData();
        end
    end

    methods
        function this = DesktopWSBDataModel()
        end

        function type = getType(~)
            type = "WSB";
        end
        
        %getClassType
        function type = getClassType(~)
            type = "WSB";
        end

        function varargout = getData(~, varargin)
            % Create a struct with field names which are the variables in the workspace.  This is
            % used by some actions to determine state (if it is empty or not)
            
            [~, ld] = internal.matlab.desktop_workspacebrowser.DesktopWSBDataModel.setNumVariables;
            varargout{1} = ld;
        end

        function size = getSize(~)
            size = [0, 0];
        end
        
        function data = updateData(~, varargin)
            data = struct;
        end

        function [data,varargout] = variableChanged(~, varargin)
            data = struct;
            varargout{1} = {};
        end

        function workspaceUpdated(~)
        end
    end

    methods(Static)
	    % When a count is provided, this is taken as the number of variables currently in the workspace.
		% Returns the persistent count, and a struct containing the same number of fields as the 
		% number of variables in the workspace.  This struct is used by actions to make choices
		% about availability.
        function [n, ld] = setNumVariables(count)
            persistent NumVariables;
            persistent LastData;

            if isempty(NumVariables)
                NumVariables = 0;
                LastData = struct;
            end

            if nargin == 1 && ~isequal(NumVariables, count)
                NumVariables = count;
                LastData = cell2struct(repmat({[]}, NumVariables, 1), "x" + (1:NumVariables));
            end

            n = NumVariables;
            ld = LastData;
        end
    end
end