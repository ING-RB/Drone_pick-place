classdef ToolGroupWindow < matlabshared.application.ApplicationWindow
    %
    
    %   Copyright 2020-2021 The MathWorks, Inc.
    properties (Hidden)
        ToolGroup;
    end
    
    properties (SetAccess = protected, Hidden)
        % GroupDocument
        %     Handle to the toolgroup document
        GroupDocument
        Actions
        StatusWidget;
        Visible = true;
        
        QuickAccessActions = {};
        QuickAccessListeners = struct;
    end
    
    properties (Access = protected)
        CloseRequestFunction;
        ClientActionListener;
        GroupActionListener;
    end
    
    methods
        function this = ToolGroupWindow(hApp)
            this@matlabshared.application.ApplicationWindow(hApp);
        end
        
        function state = uiconfirm(~, text, title, buttons, default)
            state = questdlg(text, title, buttons{:}, default);
            if isempty(state)
                state = default;
            end
        end

        function errorMessage(~, text, title)
            errordlg(text, title, 'modal');
        end

        function t = getComponentTileIndex(this, comp)
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            t = md.getClientLocation(md.getClient(getName(comp), this.ToolGroup.Name));
        end
        
        function moveComponentToTile(this, comp, tile)
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            md.setClientLocation(getName(comp), this.ToolGroup.Name, tile);
        end
        
        function b = isComponentInSameLocation(this, comp1, comp2)
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            toolGroup = this.ToolGroup.Name;
            tl1 = md.getClientLocation(md.getClient(getName(comp1), toolGroup));
            tl2 = md.getClientLocation(md.getClient(getName(comp2), toolGroup));
            
            b = tl1 == tl2;
        end
        
        function open(this)
            toolGroup = this.ToolGroup;
            if ~isempty(toolGroup)
                open(toolGroup);
                return;
            end
            hApp = this.Application;
            toolGroup = matlab.ui.internal.desktop.ToolGroup(getTitle(hApp), getTag(hApp));
            this.ToolGroup = toolGroup;
            
            notify(hApp, 'ApplicationConstructed');
            
            toolGroup.hideViewTab;
            
            if ~isempty(hApp.Toolstrip)
                toolGroup.addTabGroup(hApp.Toolstrip);
            end

            % Add DDUX logging to Toolgroup for DSD App
            [shouldDDUX, prod, name] = shouldSupportDDUX(hApp);
            if shouldDDUX
                addDDUXLogging(this.ToolGroup, prod, name);
            end
            components = getDefaultComponents(hApp);
            
            if ~hApp.usingWebFigures
                for indx = 1:numel(components)
                    toolGroup.addFigure(components(indx).Figure);
                end
            end
            
            createComponentKeyPressListener(hApp);
            
            position = getDefaultPosition(hApp);
            toolGroup.setPosition(position(1), position(2), position(3), position(4));
            
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            
            % No application can use the databrowser
            toolGroup.disableDataBrowser;
            
            % Wrap each of the qab actions into a java array.
            qabActions = this.QuickAccessActions;
            ja = javaArray('javax.swing.Action', 1);
            for indx = 1:numel(qabActions)
                ja(indx) = qabActions{indx};
            end
            this.QuickAccessActions = [];
            
            state = java.lang.Boolean.FALSE;
            c = toolGroup.Peer.getWrappedComponent;
            
            % Remove the problematic "Hide" option from the tabs.
            c.putGroupProperty(com.mathworks.widgets.desk.DTGroupProperty.PERMIT_DOCUMENT_BAR_HIDE, state);
            
            % Add the qab actions.
            if ~isempty(qabActions)
                c.putGroupProperty(com.mathworks.widgets.desk.DTGroupProperty.CONTEXT_ACTIONS, ja);
            end
            
            % Make the toolgroup visible.
            toolGroup.open;
            toolName = toolGroup.Name;
            drawnow
            
            desktop = com.mathworks.mde.desk.MLDesktop.getInstance;
            grpCont = javaMethodEDT('getGroupContainer', desktop, toolName);
            this.GroupDocument = javaMethodEDT('getTopLevelAncestor',grpCont);
            
            prop = com.mathworks.widgets.desk.DTClientProperty.PERMIT_USER_CLOSE;

            % Set the closable state for each component.  Gather up all the
            % figure handles to the intrinsic components.
            for indx = 1:numel(components)
                if ~isCloseable(components(indx)) && ~hApp.usingWebFigures
                    md.getClient(getName(components(indx)), toolName).putClientProperty(prop, state);
                end
            end
            addToolGroupListeners(this);
        end
        
        function addToolGroupListeners(this)
            toolGroup = this.ToolGroup;
            this.ClientActionListener = event.listener(toolGroup, 'ClientAction', @this.onClientAction);
            this.GroupActionListener  = event.listener(toolGroup, 'GroupAction',  @this.onGroupAction);
        end
        
        function delete(this)
            delete(this.ToolGroup);
        end
        
        function b = isOpen(this)
            b = ~isempty(this.ToolGroup) && isvalid(this.ToolGroup);
        end
        
        function focusOnComponent(this, comp)
            
            app = this.Application;
            fig = comp.Figure;
            if ~isequal(fig, app.CurrentHover)
                md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
                ssh = get(0, 'ShowHiddenHandles');
                set(0, 'ShowHiddenHandles', 'on');
                currentFig = get(0, 'CurrentFigure');
                set(0, 'ShowHiddenHandles', ssh);
                % If the current figure is not part of the toolgroup, do
                % not use showClient below because it will grab focus away
                % from the figure thats on top of the UI.h = 
                if isempty(md.getClient(currentFig.Name, this.ToolGroup.Name))
                    return;
                end
                if ~isempty(md.getClient(fig.Name, this.ToolGroup.Name))
                    this.ToolGroup.showClient(getName(comp));
                    drawnow;
                    app.CurrentHover = fig;
                end
            end
        end
        
        function [x,y,w,h] = getPosition(this)
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            loc = md.getGroupLocation(this.ToolGroup.Name);
            
            xy = loc.getFrameLocation;
            wh = loc.getFrameSize;
            x = xy.x;
            y = xy.y;
            w = wh.width;
            h = wh.height;
            if nargout < 2
                x = [x y w h];
            end

            pixelRatio = getPixelRatio(this);
            x = x / pixelRatio;
            y = y / pixelRatio;
            w = w / pixelRatio;
            h = h / pixelRatio;
        end
        
        function pos = getCenterPosition(this, sz)
            pos = matlabshared.application.getCenterPosition(sz, this.ToolGroup.Name);
        end

        function pixelRatio = getPixelRatio(~)
            ppss = get(0, 'ScreenSize');
            if ismac
                dpss = ppss;
            else
                dpss = matlab.ui.internal.PositionUtils.getDevicePixelScreenSize;
            end
            pixelRatio = dpss(4)/ppss(4);
        end
        
        function addComponent(this, newComponent, docked)
            if docked
                toolGroup = this.ToolGroup;
                toolGroup.addFigure(newComponent.Figure);
                if ~isCloseable(newComponent)
                    md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
                    prop = com.mathworks.widgets.desk.DTClientProperty.PERMIT_USER_CLOSE;
                    state = java.lang.Boolean.FALSE;
                    drawnow;
                    client = md.getClient(getName(newComponent), toolGroup.Name);
                    client.putClientProperty(prop, state);
                end
                createComponentKeyPressListener(this.Application);
            end
        end
        
        function removeComponent(~, ~)
            % NO OP
        end
        
        function addQabButton(this, name, callback, varargin)
            
            % Create an action object for the QAB to use.
            action = javaMethodEDT('getAction','com.mathworks.mlwidgets.toolgroup.Utils', ['My ' name],javax.swing.ImageIcon);
            javaMethodEDT('setEnabled', action, false); % Initially disabled
            
            % Create a listener to act as the callback.
            this.QuickAccessListeners.(name) = addlistener(action.getCallback, 'delayed', callback);
            
            % Cache the action to be added to the UI later.
            this.QuickAccessActions{end+1} = action;
            
            % Set the tool's name so the QAB knows which button to
            % associate with the action.
            ctm = com.mathworks.toolstrip.factory.ContextTargetingManager;
            ctm.setToolName(action, name);
            this.Actions.(name) = action;
        end
        
        function attachCloseRequest(this, fcn)
            setClosingApprovalNeeded(this, true);
            this.CloseRequestFunction = fcn;
        end
        
        function setQabEnabled(this, action, state)
            javaMethodEDT('setEnabled', this.Actions.(action), state);
        end
        
        function setQabName(this, action, name)
            javaMethodEDT('setName', this.Actions.(action), name);
        end
        
        function b = enableQabNaming(this, varargin)
            ja = javaArray('java.lang.String', 1);
            ja(1) = javax.swing.Action.NAME;

            actions = this.Actions;
            for indx = 1:numel(varargin)
                actions.(varargin{indx}).putValue(com.mathworks.toolstrip.factory.ContextTargetingManager.PROPERTIES_TO_INJECT_KEY, ja);
            end
            b = true;
        end
        
        function setStatus(this, statusText)
            statusWidget = this.StatusWidget;
            if isempty(statusWidget)
                md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
                f  = md.getFrameContainingGroup(this.ToolGroup.Name);
                sb = javaObjectEDT('com.mathworks.mwswing.MJStatusBar');
                javaMethodEDT('setSharedStatusBar', f, sb);
                statusWidget = javaObjectEDT('javax.swing.JLabel', '');
                sb.add(statusWidget);
                this.StatusWidget = statusWidget;
            end
            javaMethodEDT('setText', statusWidget, statusText);
        end
        
        function status = getStatus(this)
            statusWidget = this.StatusWidget;
            if isempty(statusWidget)
                status = '';
            else
                status = javaMethodEDT('getText', statusWidget);
            end
        end
        
        function updateTitle(this)
            toolGroup = this.ToolGroup;
            if ~isempty(toolGroup)
                toolGroup.Title = getTitle(this.Application);
            end
        end
        
        function close(this)
            group = this.ToolGroup;
            if isempty(group)
                return;
            end
            setClosingApprovalNeeded(this, false);
            close(group);
%             this.ToolGroup = [];
        end
        
        function w = freezeUserInterface(this)
            tg = this.ToolGroup;
            if isempty(tg)
                w = [];
                return;
            end
            waiting = isWaiting(tg);
            setWaiting(tg, true);
            w = onCleanup(@() setTGWaiting(tg, waiting));
        end
               
        function name = getApplicationName(this)
            name = this.ToolGroup.Name;
        end
        
        function b = isDocked(this, comp)
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            b = ~isempty(md.getClient(comp.getName, this.ToolGroup.Title));
        end
    end
    
    methods (Hidden)
        
        function b = isClosingApprovalNeeded(this)
            b = isClosingApprovalNeeded(this.ToolGroup);
        end
        
        function setClosingApprovalNeeded(this, value)
            this.ToolGroup.setClosingApprovalNeeded(value);
        end
        
        function onClientAction(this, ~, ev)
            fig = ev.EventData.Client;
            if ~isempty(fig) && ishghandle(fig) && isappdata(fig, 'Handle')
                hComponent = getappdata(fig, 'Handle');
            else
                return;
            end
            type = ev.EventData.EventType;
            if strcmp(type, 'DEACTIVATED')
                onBlur(hComponent);
            elseif strcmp(type, 'ACTIVATED')
                app = this.Application;
                app.CurrentHover = hComponent.Figure;
                onFocus(hComponent);
                notify(app, 'ComponentActivated');
            end
        end
        
        function onGroupAction(this, h, ev)
            type = ev.EventData.EventType;
            if strcmp(type, 'CLOSED')
                finalizeClose(this.Application);
            elseif strcmp(type, 'CLOSING') && isClosingApprovalNeeded(h)
                fcn = this.CloseRequestFunction;
                if ~isempty(fcn)
                    b = fcn(this.Application);
                    if b
                        initializeClose(this.Application);
                        approveClose(h);
                    else
                        vetoClose(h);
                    end
                end
                
            end
        end
        
        function group = getDocumentGroup(~, ~)
            % Toolgroups do not use document groups.
            group = [];
        end
    end
end

function setTGWaiting(tg, waiting)
if isvalid(tg)
    setWaiting(tg, waiting);
end
end
function addDDUXLogging(toolGroup, productName, appName)
% addDDUXLogging - Add Data Driven User Experience logging to MCOS
% Toolstrip app

% Provide product name (e.g. 'Automated Driving Toolbox')
toolGroup.Peer.getWrappedComponent.putGroupProperty( ...
    com.mathworks.widgets.desk.DTGroupProperty.USAGE_DATA_PRODUCT, productName);

% Provide app name (e.g. 'Driving Scenario Designer')
toolGroup.Peer.getWrappedComponent.putGroupProperty( ...
    com.mathworks.widgets.desk.DTGroupProperty.USAGE_DATA_SCOPE, appName);
end
% [EOF]
