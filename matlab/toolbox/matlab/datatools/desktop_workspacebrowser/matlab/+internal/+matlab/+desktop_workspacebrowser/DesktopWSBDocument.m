classdef DesktopWSBDocument < internal.matlab.variableeditor.Document

    % Document class for the Desktop Workspace Browser

    % Copyright 2024-2025 The MathWorks, Inc.

    properties(Constant)
        DesktopWSBUserContext = 'MOTW_Workspace';
    end

    properties
        Workspace = 'debug';
        Name = 'who';
        DocID;
    end

    events
        DoubleClickOnVariable;
        OpenSelection;
        DropEvent;
    end

    methods
        function this = DesktopWSBDocument(manager)
            DataModel = internal.matlab.desktop_workspacebrowser.DesktopWSBDataModel;
            ViewModel = internal.matlab.desktop_workspacebrowser.DesktopWSBViewModel(DataModel);
            this@internal.matlab.variableeditor.Document(manager, DataModel, ViewModel, UserContext=internal.matlab.desktop_workspacebrowser.DesktopWSBDocument.DesktopWSBUserContext);
        end

        function [data,varargout] = variableChanged(~, varargin)
            data = [];
            varargout = {};
        end
    end
end