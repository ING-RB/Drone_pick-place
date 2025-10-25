classdef (Abstract) Control < matlab.ui.internal.toolstrip.base.Component & matlab.ui.internal.toolstrip.mixin.WidgetBehavior_Mnemonic
    % Base class for MCOS toolstrip controls.
    
    % Copyright 2013-2019 The MathWorks, Inc.
    
    %% -----------  User-invisible properties --------------------
    properties (Access = private)
        handledExceptionTypes = {'MATLAB:class:SetProhibited'};
    end
    
    properties (Access = protected)
        % Action object
        Action
        % ActionListener
        ActionPerformedListener
        ActionPropertySetListener
    end
    
    %% ----------- User-visible properties --------------------------
    properties (Dependent, Access = public)
        % Property "Description": 
        %
        %   The description of a control, displayed as a tooltip when mouse
        %   is hoving over. It is a string and the default value is ''. It
        %   is writable.
        %
        %   Example:
        %       btn = matlab.ui.internal.toolstrip.Button('Submit')
        %       btn.Description = 'Submit Button'
        Description
        % Property "Enabled": 
        %
        %   The enabling status of a control.
        %   It is a logical and the default value is true.
        %   It is writable.
        %
        %   Example:
        %       btn = matlab.ui.internal.toolstrip.Button('Submit')
        %       btn.Enabled = false
        Enabled
    end
    
    properties (Dependent, Access = public, Hidden)
        % Property "Shortcut": 
        %
        %   The shortcut key of an action
        %   It is a string and the default value is ''.
        %   It is writable.
        %
        %   Example:
        %       action.Shortcut = 'S'
        Shortcut
    end
    
    %% ----------------------------------------------------------------------------
    % Public methods
    methods
        
        %% Constructor
        function this = Control(type, varargin)
            % set type
            this.Type = type;
            % create widget property maps (action properties are handled
            % inside the Action object)
            this.buildWidgetPropertyMaps();
            % create or add Action object
            if nargin == 2 && isa(varargin{1},'matlab.ui.internal.toolstrip.base.Action')
                this.Action = varargin{1};
            else
                % create action object with all the peer node properties
                this.Action = matlab.ui.internal.toolstrip.base.Action();
                % add dynamic properties to the Action object
                this.addActionProperties();
            end
            % add listener to peer node events
            this.addListeners();
        end
        
        function delete(this)
            % remove any listeners on Action for robustness
            this.removeListeners();
        end
        
        %% Get/Set Methods
        % Enabled        
        function value = get.Enabled(this)
            % GET function for Enabled property.
            value = this.Action.Enabled;
        end
        function set.Enabled(this, value)
            % SET function for Enabled property.
            try
                this.set_Enabled(value);
            catch me
                if any(contains(this.handledExceptionTypes, me.identifier))
                    throwAsCaller(me);
                else
                    rethrow(me);
                end
            end
        end
        % Description
        function value = get.Description(this)
            % GET function for Description property.
            value = this.Action.Description;
        end
        function set.Description(this, value)
            % SET function for Description property.
            try
                this.set_Description(value);
            catch me
                if any(contains(this.handledExceptionTypes, me.identifier))
                    throwAsCaller(me);
                else
                    rethrow(me);
                end
            end
        end
        % Shortcut
        function value = get.Shortcut(this)
            % GET function for Shortcut property.
            value = this.Action.Shortcut;
        end
        function set.Shortcut(this, value)
            % SET function for Shortcut property.
            this.Action.Shortcut = value;
        end
        
        %% Special utility methods
		function showTearOffDialog(anchor, dialog, varargin)
            % Method "showTearOffDialog": 
            %
            %   Display a tear-off dialog below this control.
            %
            %   Example #1 (common case):
            %       showTearOffDialog(this, dialog);
            %   where: 
            %       "dialog" must be a "toolpack.component.TSTearOffPopup" object
            %       The floating mode is determined by the "dialog.Floating" property
            %
            %   Example #2 (special case to enfore the dialog opens in a particular floating mode):
            %       showTearOffDialog(this, dialog, floating);
            %   where: 
            %       "floating" (true/false) overwrites what is set in the "dialog.Floating" property
            %
            %   Java swing rendering only
            
            % for MGG use only
            jdialog = dialog.Peer.getWrappedComponent();
            jrootpane = jdialog.getRootPane();
            javaMethodEDT('putClientProperty',jrootpane(1),'anchor_id',anchor.getId());
            % parse optional inputs
            switch nargin
                case 2
                    Toolstrip = [];
                case 3
                    if islogical(varargin{1})
                        dialog.Peer.setFloating(varargin{1});
                        Toolstrip = [];
                    elseif isa(varargin{1},'matlab.ui.internal.toolstrip.Toolstrip')
                        Toolstrip = varargin{1};
                    else
                        error(message('MATLAB:toolstrip:general:LogicalArgumentNeeded'));
                    end
                case 4
                    if islogical(varargin{1})
                        dialog.Peer.setFloating(varargin{1});
                    else
                        error(message('MATLAB:toolstrip:general:LogicalArgumentNeeded'));
                    end
                    Toolstrip = varargin{2};
            end
            % find MCOS Toolstrip object (top level)
            if isempty(Toolstrip)
                child = anchor;
                parent = anchor.Parent;
                while ~isempty(parent)
                    child = parent;
                    parent= child.Parent;
                end
                if isa(child,'matlab.ui.internal.toolstrip.Toolstrip')
                    Toolstrip = child;
                else
                    return
                end
            end
            if ~isempty(Toolstrip.ToolstripSwingService)
                janchor = Toolstrip.ToolstripSwingService.Registry.getWidgetById(anchor.getId());
                javaMethodEDT('pack',jdialog);
                javaMethodEDT('showPopup','com.mathworks.toolbox.shared.controllib.desktop.TearOffDialogWrapper',janchor,jdialog,'SOUTH');
            end
        end
        
        function showUIFigureDialog(anchor, fig)
            % Method "showUIFigureDialog": 
            %
            %   Display a uifigure-based dialog below this control.
            %
            %   Example:
            %       showUIFigureDialog(anchor, fig);
            %   where: 
            %       "anchor" must be a "matlab.ui.internal.toolstrip.***" object, typically a Button 
            %       "fig" must be a "uifigure", not a "figure"
            WarnStates = warning;
            warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
            jf = matlab.ui.internal.JavaMigrationTools.suppressedJavaFrame(fig);
            warning(WarnStates);
            if ~isempty(jf)
                fprintf('"showUIFigureDialog" only displays a uifigure. Use "showFigureDialog" to display a regular figure.\n')
            end
            child = anchor;
            parent = anchor.Parent;
            while ~isempty(parent)
                child = parent;
                parent= child.Parent;
            end
            if isa(child,'matlab.ui.internal.toolstrip.Toolstrip')
                Toolstrip = child;
            else
                return
            end
            if ~isempty(Toolstrip.ToolstripSwingService)
                janchor = Toolstrip.ToolstripSwingService.Registry.getWidgetById(anchor.getId());
                if janchor.isShowing()
                    pt = javaMethodEDT('getLocationOnScreen',janchor); % pt is anchor top left
                    pt.y = pt.y + janchor.getVisibleRect().height; % pt is anchor bottom left
                    screen_size = get(0,'ScreenSize');
                    old_pos = get(fig,'Position');
                    dpi_ratio = com.mathworks.util.ResolutionUtils.scaleSize(100)/100;
                    new_x = pt.getX()/dpi_ratio; % figure outer left
                    new_y = screen_size(end)-pt.getY/dpi_ratio-old_pos(4)-30; % figure outer bottom
                    fig.Position = [new_x new_y old_pos(3) old_pos(4)];
                else
                    centerfig(fig);
                end
                fig.Visible = 'on';
            end
        end

		function showFigureDialog(anchor, fig, varargin)
            % Method "showFigureDialog": 
            %
            %   Display a figure-based dialog below this control.
            %
            %   Example:
            %       showFigureDialog(anchor, fig);
            %   where: 
            %       "anchor" must be a "matlab.ui.internal.toolstrip.***" object, typically a Button 
            %       "fig" must be a "figure", not a "uifigure"
            WarnStates = warning;
            warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
            jf = matlab.ui.internal.JavaMigrationTools.suppressedJavaFrame(fig);
            warning(WarnStates);
            if isempty(jf)
				fprintf('"showFigureDialog" only displays a regular figure. Use "showUIFigureDialog" to display a uifigure.\n')
            else
                screen_size = get(0,'ScreenSize');
                old_pos = get(fig,'OuterPosition');
                dpi_ratio = com.mathworks.util.ResolutionUtils.scaleSize(100)/100;
                % find MCOS Toolstrip object (top level)
                if nargin>=3
                    Toolstrip = varargin{1};
                else
                    child = anchor;
                    parent = anchor.Parent;
                    while ~isempty(parent)
                        child = parent;
                        parent= child.Parent;
                    end
                    if isa(child,'matlab.ui.internal.toolstrip.Toolstrip')
                        Toolstrip = child;
                    else
                        return
                    end
                end
                if ~isempty(Toolstrip.ToolstripSwingService)
                    janchor = Toolstrip.ToolstripSwingService.Registry.getWidgetById(anchor.getId());
                    if janchor.isShowing()
                        pt = javaMethodEDT('getLocationOnScreen',janchor); % pt is anchor top left
                        pt.y = pt.y + janchor.getVisibleRect().height; % pt is anchor bottom left
                        new_x = pt.getX()/dpi_ratio-5; % figure outer left
                        new_y = screen_size(end)-(pt.getY/dpi_ratio+old_pos(4)); % figure outer bottom
                        fig.OuterPosition = [new_x new_y old_pos(3) old_pos(4)];
                    else
                        centerfig(fig);
                    end
                    fig.Visible = 'on';
                end
            end
        end
        
    end
    
    methods (Hidden)
        %% Sharing action object
        function shareWith(this, controls)
            % Method "shareWith":
            %
            %   shareWith(control1, control2): share properties and
            %   callbacks of "control1" with "control2".  "control1" and
            %   "control2" must have compatible types.
            action = this.getAction();
            for ct=1:length(controls)
                if this.checkAction(controls(ct))
                    controls(ct).setAction(action);
                else
                    error(message('MATLAB:toolstrip:control:invalidShareWith'));
                end
            end
        end
        
    end
    
    %% common methods
    methods (Access = protected)

        function set_Description(this, value)
            % SET method implementation for Description property.
            this.Action.Description = value;
        end

        function set_Enabled(this, value)
            % SET method implementation for Enabled property.
            this.Action.Enabled = value;
        end
        
        function [mcos, peer] = getWidgetPropertyNames_Control(this)
            % provide MCOS and peer node name map for widget properties
            [mcos1, peer1] = this.getWidgetPropertyNames_Component();
            [mcos2, peer2] = this.getWidgetPropertyNames_Mnemonic();
            mcos = [mcos1;mcos2];
            peer = [peer1;peer2];
        end
        
        function addListeners(this)
            this.ActionPerformedListener = addlistener(this.Action, 'ActionPerformed', @(event, data) ActionPerformedCallback(this, event, data));
            this.ActionPropertySetListener = addlistener(this.Action, 'ActionPropertySet', @(event, data) ActionPropertySetCallback(this, event, data));
        end
        
        function removeListeners(this)
            delete(this.ActionPerformedListener);
            delete(this.ActionPropertySetListener);
        end
        
        function ActionPerformedCallback(this, event, data) %#ok<*INUSD>
            %display('action performed in an action object by the client.')
        end
        
        function ActionPropertySetCallback(this, event, data)
            %display('property set in an action object by the client.')
        end
        
        function action = getAction(this)
            % Method "getAction":
            %
            %   action = getAction(control): return the action object
            %   associated with this control.
            action = this.Action;
        end
        
        function action = setAction(this, action)
            % Method "setAction":
            %
            %   setAction(control, action): set the action object
            %   associated with this control.
            this.Action = action;
            if ~isempty(action.Id)
                this.setPeerProperty('actionId', action.Id);
            end
            this.removeListeners();
            this.addListeners();
        end
        
    end
    
    %% hidden methods
    methods (Hidden)    
        
        function render(this, channel, parent, varargin)
            % Method "render"
            %
            %   create the widget peer node (at the orphan root) and add it
            %   to its parent (move to parent node).  create the action
            %   peer node (at the action root). There is no children node
            %   under a control.
            
            % create widget and action node if they do not exist
            if ~hasPeerNode(this)
                % create widget peer node
                this.PeerModelChannel = channel;
                widget_properties = this.getWidgetProperties();
                this.createPeer(widget_properties);
                % create action peer node
                this.Action.render([channel '_Action']);
                % link action peer node to widget peer node
                this.setPeerProperty('actionId', this.Action.Id);
            end
            % move this peer node to parent
            this.moveToTarget(parent,varargin{:});
        end
        
    end
    
    %% abstract methods
    methods (Abstract, Access = protected)
        addActionProperties(this)
        checkAction(this)
    end

end
