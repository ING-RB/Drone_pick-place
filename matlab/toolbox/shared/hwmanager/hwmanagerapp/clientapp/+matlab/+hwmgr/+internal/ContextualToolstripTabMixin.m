classdef (Abstract) ContextualToolstripTabMixin < handle
    %CONTEXTUALTABMIXIN Mixin class providing an API for controlling
    %Contextual Toolstrip Tabs.
    
    % Copyright 2023 The MathWorks, Inc.

    properties (Constant)
        % CONTEXTTABTAG Use the same Tag for contextual tabs as Toolstrip
        % class expects.
        ContextTabTag = matlab.hwmgr.internal.Toolstrip.ContextTabTag
    end

    properties (Access = private)
        % Function handles for each of the Contextual Tab control
        % functions. These are set via `setContextualTabControlFcns`
        % method. Default values match expected signature but all return
        % false.
        AddContextTabFcn              (1,1) function_handle = @(~,~) false
        ShowContextTabFcn             (1,1) function_handle = @(~)   false
        RemoveContextTabFcn           (1,1) function_handle = @(~)   false
        RemoveAllContextTabsFcn       (1,1) function_handle = @( )   false
    end
    
    methods (Access = public)
        function setContextualTabControlFcns(obj, controller)
            arguments
                obj (1,1) matlab.hwmgr.internal.ContextualToolstripTabMixin
                controller (1,1)
            end
            % Capture function handles for controlling context tab
            % toolstrip.
            obj.AddContextTabFcn              = controller.addContextTab;
            obj.ShowContextTabFcn             = controller.showContextTab;
            obj.RemoveContextTabFcn           = controller.removeContextTab;
            obj.RemoveAllContextTabsFcn       = controller.removeAllContextTabs;
        end

    end

    methods (Access = protected)
        function tab = createContextTab(obj, title)
            arguments (Input)
                obj (1,1) matlab.hwmgr.internal.ContextualToolstripTabMixin
                title {mustBeTextScalar} % Accept string or char
            end
            arguments (Output)
                tab (1,1) matlab.ui.internal.toolstrip.Tab
            end
            % Create a new context tab with the given title, where title is a
            % string.
            tab = matlab.ui.internal.toolstrip.Tab(title);
            tab.Tag = obj.ContextTabTag;
        end

        function success = addContextTab(obj, tab, index)
            arguments(Input)
                obj   (1,1) matlab.hwmgr.internal.ContextualToolstripTabMixin
                tab   (1,1) matlab.ui.internal.toolstrip.Tab
                index (1,:) double = []
            end
            arguments(Output)
                success (1,1) logical
            end
            % Takes a tab object as an argument and adds that tab to the
            % toolstrip, inserting at the index specified or appending to
            % the end of the toolstrip if no index is provided.
            % Returns true if tab added successfully, false otherwise.
            success = obj.AddContextTabFcn(tab, index);
        end

        function success = showContextTab(obj, tab)
            arguments (Input)
                obj (1,1)
                tab (1,1) matlab.ui.internal.toolstrip.Tab
            end
            arguments (Output)
                success (1,1) logical
            end
            % Takes a currently shown tab object and changes focus to that tab.
            % Returns true if the focus was indeed changed and false if the tab
            % was not currently being shown. Requires that argument passed be 
            % a tab object.
            success = obj.ShowContextTabFcn(tab);
        end

        function success = removeContextTab(obj, tab)
            arguments (Input)
                obj (1,1)
                tab (1,1) matlab.ui.internal.toolstrip.Tab
            end
            arguments (Output)
                success (1,1) logical
            end
            % Remove tab from the MainTabGroup to hide it. Return true if we
            % indeed hide a tab, false if tab was not shown or if tab was the main 
            % toolstrip tab. Requires that tab be a valid MATLAB tab object.
            success = obj.RemoveContextTabFcn(tab);
        end

        function removeAllContextTabs(obj)
            arguments
                obj (1,1) matlab.hwmgr.internal.ContextualToolstripTabMixin
            end
            % Remove all currently shown context tabs from the toolstrip.
            obj.RemoveAllContextTabsFcn();
        end
    end
end
