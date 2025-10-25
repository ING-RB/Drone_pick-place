classdef DialogManager < handle
% DialogManager is a component that manages the life cycle of dialogs
% launched from an AppContainer-based app.  It uses ancestry information
% of the dialogs and also provides window management and other utilities.
%
% Example: app = controllib.ui.internal.dialog.showcaseApp();
%       Launch three dialogs for three plants by double-clicking the first
%       data browser.  Launch a singleton dialog by double-clicking the
%       second data browser.
%
% To use it with the "Composite" design pattern:
%   
%   In your "AppData" or "App" class: 
%       this.DialogManager = controllib.ui.internal.dialog.DialogManager()
%       this.DialogManager.attachDialogManagerToAppContainer(appcontainer)
%
% To use it with the "MixIn" design pattern:
%   
%   In your "AppData" or "App" class subclassed from "DialogManager": 
%       this.attachDialogManagerToAppContainer(appcontainer)
%
% Restrictions:
%   1. You can only register the following types of dialogs:
%           a subclass of "controllib.ui.internal.dialog.AbstractDialog"
%           a "uifigure"
%   2. A dialog is either a parent dialog or a child dialog:
%           "parent" (top-level): dialog's parent is the AppContainer
%           "child" (bottom-level): dialog's parent is a parent dialog
%           Remember, child dialog's life cycle cannot exceed its parent's
%   3. "dlg.Name" and "fig.Tag" must be unique within your app.  
%           If your dialog is a singleton, you can choose a permanent name
%           If your dialog is associated with temporary data point, use the
%           UUID associated with that data point.
%   4. It does not support ToolGroup
%
%   Methods:
%       <a href="matlab:help controllib.ui.internal.dialog.DialogManager.registerDialog">registerDialog</a>
%       <a href="matlab:help controllib.ui.internal.dialog.DialogManager.deleteDialog">deleteDialog</a>
%       <a href="matlab:help controllib.ui.internal.dialog.DialogManager.minimizeDialog">minimizeDialog</a>
%       <a href="matlab:help controllib.ui.internal.dialog.DialogManager.restoreDialog">restoreDialog</a>
%       <a href="matlab:help controllib.ui.internal.dialog.DialogManager.hasDialog">hasDialog</a>
%       <a href="matlab:help controllib.ui.internal.dialog.DialogManager.findDialog">findDialog</a>
%       <a href="matlab:help controllib.ui.internal.dialog.DialogManager.focusDialog">focusDialog</a>
%       <a href="matlab:help controllib.ui.internal.dialog.DialogManager.centerDialog">centerDialog</a>

% Author(s): Rong Chen
% Copyright 2019-2020 The MathWorks, Inc.

    properties
        DialogRegistry
    end

    properties (Access=private,Transient)
        AppWindowStateListener
        AppFigureCenterListener
        DialogWindowStateListeners
        DialogDestroyedListeners
    end
    
    methods        
        %% Constructor
        function this = DialogManager()
            this.DialogRegistry = containers.Map;
        end
        %% Associate with AppContainer
        function attachDialogManagerToAppContainer(this, appcontainer)
            arguments
                this (1,1) controllib.ui.internal.dialog.DialogManager
                appcontainer (1,1) matlab.ui.container.internal.AppContainer
            end
            weakThis = matlab.lang.WeakReference(this);
            weakAppContainer = matlab.lang.WeakReference(appcontainer);
            this.AppWindowStateListener = addlistener(appcontainer,'WindowStateChanged',@(src,data) handleAppContainerWindowStateChanged(weakThis.Handle,src,data));
            this.AppFigureCenterListener = addlistener(this,'putFigureAtCenter',@(src,data) centerToAppContainer(weakThis.Handle,src,data,weakAppContainer.Handle));
        end
        %% Dialog life cycle management
        function registerDialog(this, child, parentTag)
            % Register a subclass of AbstractDialog or a UIFigure launched
            % anywhere from the app.
            %
            %   For a dialog directly launched from the app, use
            %       registerDialog(this, dlg) 
            %            
            %   For a uifigure directly launched from the app, use
            %       registerDialog(this, fig) 
            %
            %   For a child dialog launched from a parent and share the
            %   same life cycle, use
            %       registerDialog(this, dlg, parentTag) 
            %            
            %   For a child uifigure launched from a parent and share the
            %   same life cycle, use
            %       registerDialog(this, fig, parentTag) 
            %
            %   Important: if a dialog launched from another dialog does
            %   not share the same life cycle by app design, do not add
            %   "parentTag" and treat it as a top-level dialog.
            
            % error out if duplicated or parent dialog does not exist
            tag = this.getTag(child);
            if this.DialogRegistry.isKey(tag)
                error('Failed to register.  Dialog with same tag already exists in the registry.')
            end
            if nargin>2 && ~this.DialogRegistry.isKey(parentTag)
                error('Failed to register.  Parent dialog does not exist in the registry.')
            end
            % register the dialog
            if nargin==2
                % parent is the app container (same life cycle)
                this.DialogRegistry(tag) = {child; ''};
            else
                this.DialogRegistry(tag) = {child; parentTag};
            end
            % listener to "minimized" and "normal" window state change in a
            % uifigure
            fig = getFigureFromTag(this, tag);
            weakThis = matlab.lang.WeakReference(this);
            this.DialogWindowStateListeners = [this.DialogWindowStateListeners;...
                addlistener(fig,'WindowStateChanged',@(src,data) handleUIFigureWindowStateChanged(weakThis.Handle,src,data))];
            % listener to dialog destruction
            this.DialogDestroyedListeners = [this.DialogDestroyedListeners;...
                addlistener(child,'ObjectBeingDestroyed',@(src,data) handleObjectBeingDestroyed(weakThis.Handle,src,data))];
        end
        function deleteDialog(this, tag)
            % Delete a subclass of AbstractDialog or a UIFigure-based
            % dialog and its children dialogs.
            %
            %       deleteDialog(this, tag)
            %
            %   Use it when you want to programmatically delete a dialog
            %   and all its children.
            if this.DialogRegistry.isKey(tag)
                % delete all the children
                keys = this.DialogRegistry.keys;
                for ct=1:length(keys)
                    data = this.DialogRegistry(keys{ct});
                    if strcmpi(data{2},tag)
                        obj = data{1};
                        delete(obj);
                    end
                end
                % delete itself
                obj = getObject(this, tag);
                delete(obj);
            end
        end
        %% Dialog window management
        function minimizeDialog(this, varargin)
            % Programmatically minimize dialogs
            %
            %   minimizeDialog(this) minimize all the dialogs launched from
            %   the app
            %
            %   minimizeDialog(this, parentTag) minimize the parent dialog
            %   and all the children dialogs.
            this.toggleWindowState('minimized', varargin{:});
        end
        function restoreDialog(this, varargin)
            % Programmatically restore dialogs
            %
            %   restoreDialog(this) restore all the dialogs
            %
            %   restoreDialog(this, parentTag) restore the parent dialog
            %   and all the children dialogs.
            this.toggleWindowState('normal',varargin{:});
        end
        %% Dialog utilities
        function registered = hasDialog(this, tag)
            % Determine whether a dialog with the specified tag is
            % registered.  Return true or false.
            %   
            %       hasDialog(this, tag);
            registered = this.DialogRegistry.isKey(tag);
        end
        function dlg = findDialog(this, tag)
            % Find a registered dialog based on its tag, return [] if not
            % found
            %   
            %       dlg = findDialog(this, tag);
            if this.DialogRegistry.isKey(tag)
                data= this.DialogRegistry(tag);
                dlg = data{1};
            else
                dlg = [];
            end
        end
        function focusDialog(this, tag)
            % Bring a registered dialog with specified tag to focus
            %   
            %       focusDialog(this, tag);
            if this.DialogRegistry.isKey(tag)
                % show and raise
                fig = getFigureFromTag(this, tag);
                figure(fig);
            end
        end
        function centerDialog(this, tag)
            % Position a registered dialog with the specified tag at the
            % center of the AppContainer or its parent dialog.
            %   
            %       centerDialog(this, tag);
            if this.DialogRegistry.isKey(tag)
                data = this.DialogRegistry(tag);
                fig = getFigureFromTag(this, tag);
                if isempty(data{2})
                    % parent is an app container
                    EventData = controllib.ui.internal.dialog.DialogManagerEventData(fig);
                    this.notify('putFigureAtCenter',EventData);
                else
                    % parent is a dialog
                    parentTag = data{2};
                    parentFig = getFigureFromTag(this, parentTag);
                    centerfig(fig, parentFig);
                end
            end
        end
        %% Destructor
        function delete(this)
            % delete all the registered dialogs
            keys = this.DialogRegistry.keys;
            for ct=1:length(keys)
                deleteDialog(this,keys{ct});
            end
            delete(this.AppWindowStateListener);
            delete(this.AppFigureCenterListener);
            delete(this.DialogWindowStateListeners);
            delete(this.DialogDestroyedListeners);
        end
    end
    
    events
        putFigureAtCenter
    end
    
    methods (Access = private)
        
        function handleAppContainerWindowStateChanged(this,src,~)
            import matlab.ui.container.internal.appcontainer.*;
            switch src.WindowState
                case AppWindowState.MINIMIZED
                    this.minimizeDialog();
                case {AppWindowState.NORMAL, AppWindowState.MAXIMIZED}
                    this.restoreDialog();
            end
        end
        
        function handleUIFigureWindowStateChanged(this,src,eventdata)
            switch eventdata.WindowState
                case 'minimized'
                    this.minimizeDialog(src.Tag);
                case 'normal'
                    this.restoreDialog(src.Tag);
            end
        end
        
        function handleObjectBeingDestroyed(this,src,~)
            % remove all the children from registry and delete them as well
            tag = this.getTag(src);
            keys = this.DialogRegistry.keys;
            for ct=1:length(keys)
                data = this.DialogRegistry(keys{ct});
                if strcmpi(data{2},tag)
                    obj = data{1};
                    delete(obj);
                end
            end
            % remove itself from registry
            this.DialogRegistry.remove(tag);
        end
        
        function centerToAppContainer(~,~,data,appcontainer)
            fig = data.Figure;
            screensize = get(0,'ScreenSize');
            units = fig.Units;
            fig.Units = 'pixels';
            appsize = appcontainer.WindowBounds; % top-left is [0 0]
            appsize(2) = screensize(4) - (appsize(2)+appsize(4)); % bottom-left is [0 0]
            center = [appsize(1)+appsize(3)/2 appsize(2)+appsize(4)/2];
            fig.Position = [min(max(center(1)-fig.Position(3)/2,0),screensize(3)-fig.Position(3)) min(max(center(2)-fig.Position(4)/2,0),screensize(4)-fig.Position(4)) fig.Position(3:4)];
            figure(fig);
            fig.Units = units;
        end            
        
        function tag = getTag(~, obj)
            if isa(obj,'controllib.ui.internal.dialog.AbstractDialog')
                tag = char(obj.Name);
            else
                tag = char(obj.Tag);
            end
        end
        
        function obj = getObject(this, tag)
            data = this.DialogRegistry(tag);
            obj = data{1};
        end
        
        function fig = getFigureFromTag(this, tag)
            % tag points to a registered uifigure or AbstractDialog and
            % returns a uifigure
            data = this.DialogRegistry(tag);
            dlg = data{1};
            if isa(dlg,'controllib.ui.internal.dialog.AbstractDialog')
                fig = dlg.getWidget;
            else
                fig = dlg;
            end
        end
         
        function toggleWindowState(this, mode, parentTag)
            if nargin == 2
                % all the dialogs
                keys = this.DialogRegistry.keys;
                for ct=1:length(keys)
                    fig = getFigureFromTag(this, keys{ct});
                    fig.WindowState = mode;
                end
            else
                % parent dialog
                fig = getFigureFromTag(this, parentTag);
                fig.WindowState = mode;
                % all the children dialog
                keys = this.DialogRegistry.keys;
                for ct=1:length(keys)
                    data = this.DialogRegistry(keys{ct});
                    if strcmpi(data{2},parentTag)
                        fig = getFigureFromTag(this, keys{ct});
                        fig.WindowState = mode;
                    end
                end
            end
        end
        
    end
    
end

