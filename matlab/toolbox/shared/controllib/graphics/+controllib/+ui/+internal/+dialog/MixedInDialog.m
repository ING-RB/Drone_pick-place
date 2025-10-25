classdef MixedInDialog < handle
    % MixedIn class that wraps a "uifigure" and behave like a dialog.
    
    % Author(s): Rong Chen
    % Copyright 2019-2023 The MathWorks, Inc.
    
    %% Public properties
    properties (Dependent)
        % Property "Name": 
        %   dialog id, must be a string
        Name
        % Property "Title": 
        %   dialog title, must be a string
        Title
    end
    
    properties
        % Property "CloseMode": 
        % 
        % The "Close", a.k.a. "Exit" or "Cross", button supports three
        % different types of behavior:
        %
        %   "hide": when close button is clicked, the dialog becomes
        %           hidden. When "show" is called, the dialog appears in
        %           the same state (i.e. any uncommitted changes are still
        %           there because "updateUI" is not used in the "show").
        %           If you don't attach a listener to this event, the event
        %           is not fired.  If you attach a listener, uifigure will
        %           stay visible until you explcitly hide it in the callback.
        %
        %   "cancel": when close button is clicked, uifigure becomes
        %             hidden. When "show" is called, uifigure is refreshed
        %             with data truth (i.e. any uncommitted changes are
        %             lost because "updateUI" is used in the "show"). Use
        %             "CloseEvent" to approve or veto the "cancel"
        %             operation.  If you don't attach a listener to this
        %             event, the event is not fired.  If you attach a
        %             listener, uifigure will stay visible until you
        %             explcitly hide it in the callback.
        %
        %             This is the default mode.
        %
        %   "destroy": when close button is clicked, the uifigure is
        %              deleted. When "show" is called, the dialog is
        %              rebuilt with data truth (i.e. any uncommitted
        %              changes are lost because "updateUI" is used in the
        %              "show"). Use "CloseEvent" to approve or veto the
        %              "destroy" operation.  If you don't attach a listener
        %              to this event, the event is not fired.  If you
        %              attach a listener, uifigure will stay visible until
        %              you explcitly delete it in the callback.
        CloseMode(1,:) char {mustBeMember(CloseMode,{'hide','cancel','destroy'})} = 'cancel'
    end
    
    properties (Access = private)
        % Name
        pName = ''
        % Title
        pTitle = ''
    end
    
    properties (Dependent, SetAccess = private)
        % Property "IsVisible": 
        %   true if uifigure exists and is visible
        IsVisible
        % Property "IsWidgetValid": 
        %   true if uifigure exists and is valid
        IsWidgetValid
    end
    
    %% Protected properties
    properties(Access = protected, Transient)
        % Reference to uifigure
        UIFigure
    end
    
    %% Hidden property
    properties(Hidden)
        zCreateDefaultGridLayout = true;
    end
    
    %% Events
    events
        % Event "CloseEvent": 
        %   Event is fired when "Close" button in the uifugure is click and
        %   there are listeners attached to it. You can use this event to
        %   (1) approve or veto the cancel/destroy action and/or (2) carry
        %   out extra work.  If approved, call "hide(dlg)" to continue with
        %   the "hide"/"cancel" action or call "delete(getWidget(dlg))" to
        %   continue with the "destroy" action.
        CloseEvent
    end
    
    %% Public methods
    methods
        
        %% getters and setters
        % Name (corresponds to uifigure.Tag)
        function value = get.Name(this)
            value = this.pName;
        end
        function set.Name(this, value)
            this.pName = value;
            if this.IsWidgetValid
                this.UIFigure.Tag = value;
            end
        end
        % Title (corresponds to uifigure.Name)
        function value = get.Title(this)
            value = this.pTitle;
        end
        function set.Title(this, value)
            this.pTitle = value;
            if this.IsWidgetValid
                this.UIFigure.Name = value;
            end
        end
        % IsVisible (corresponds to uifigure.Visible)
        function value = get.IsVisible(this)
            if this.IsWidgetValid
                value = strcmp(this.UIFigure.Visible,'on');
            else
                value = false;
            end
        end
        % IsWidgetValid (true if uifigure exists and is valid)
        function value = get.IsWidgetValid(this)
            value = ~isempty(this.UIFigure) && isvalid(this.UIFigure);
        end

        %% get uifigure
        function obj = getWidget(this)
            % Method "getWidget": 
            %   obj = getWidget(this) returns the handle of uifigure.
            %   The method builds the uifigure if it doesn't exist.
            if ~this.IsWidgetValid
                buildDialog(this);
            end
            obj = this.UIFigure;
        end
        
        %% display
        function hide(this)
            % Method "hide": 
            %   "hide(this)" hides the dialog.
            if this.IsWidgetValid
                this.UIFigure.Visible = 'off';
            end
        end
        
        function show(this, varargin)
            % Method "show": 
            %   
            % Display the dialog.
            %
            %   show(this)                  
            %       display dialog at the current position
            %
            %   show(this, [])
            %       display dialog at the center of screen
            %
            %   show(this, anchor)
            %       display dialog at the center of an anchor.  "anchor"
            %       can be a "figure", a "uifigure", or a subclass of
            %       "AbstractDialog".
            %
            %   show(this, anchor, region) 
            %       display dialog relative to the above anchor.  "region"
            %       can be EAST, SOUTH, WEST, NORTH and CENTER.
            %
            %   show(this, control) 
            %       display dialog under a control.  "control" can be
            %       either a ui control or a MCOS Toolstrip control.
            %
            %   show(this, [xpos ypos]) 
            %       display dialog with its top-left corner position
            %       specified as [xpos ypos].  [0 0] is the bottom-left
            %       corner of the screen.
            %
            %   If "CloseMode" is "hide", "updateUI" is not called in
            %   "show", and thus, the dialog is displayed in the same state
            %   as before hiding.
            %
            %   If "CloseMode" is "cancel" or "destroy", "updateUI"
            %   is called in "show", and thus, the dialog is refreshed to
            %   be consistent with data truth.
            
            % create the dialog widget if it is not created yet
            if this.IsWidgetValid
                FirstTime = false;
            else
                buildDialog(this);
                FirstTime = true;
            end
            % update the dialog only when CloseMode is not "hide"
            if FirstTime == true || ~strcmp(this.CloseMode,'hide')
                updateUI(this);
            end
            % position
            if nargin<=2
                region = 'CENTER';
            else
                region = varargin{2};
            end
            if nargin==1
                if FirstTime
                    centerfig(this.UIFigure,0);
                end
            else
                anchor = varargin{1};
                if isempty(anchor)
                    centerfig(this.UIFigure,0);
                elseif isa(anchor,'matlab.ui.container.internal.AppContainer')
                    positionFigureOnAppContainer(anchor, this.UIFigure);
                elseif isa(anchor,'matlab.ui.Figure')
                    % anchor is a figure or uifigure
                    localPositionDialog_Figure(this.UIFigure,anchor,region);
                elseif isa(anchor,'controllib.ui.internal.dialog.AbstractDialog')
                    % anchor is a AbstractDialog
                    localPositionDialog_Figure(this.UIFigure,anchor.UIFigure,region);
                elseif isa(anchor,'matlab.ui.internal.toolstrip.base.Control')
                    % anchor is a Toolstrip 2.0 control
                    isSupportedComplexSwing = matlab.internal.capability.Capability.isSupported(matlab.internal.capability.Capability.ComplexSwing);
                    if isSupportedComplexSwing
                        showUIFigureDialog(anchor,this.UIFigure);
                    else
                        % TBD MOTW
                    end
                elseif contains(class(anchor),'matlab.ui.control')
                    % anchor is a ui control
                    localPositionDialog_UIControl(this.UIFigure,anchor);
                elseif isnumeric(anchor)
                    % anchor is a point of top-left corner
                    old_pos = get(this.UIFigure,'Position');
                    this.UIFigure.Position = [anchor(1) anchor(2) old_pos(3) old_pos(4)];
                end
            end
            % show and raise
            figure(this.UIFigure);   
        end
        
        %% close
        function close(this)
            % Method "close": 
            %   "close(this)" programmatically closes the dialog.  It means
            %   "hide", "cancel" or "destroy", based on "CloseMode".
            if strcmp(this.CloseMode,'destroy')
                delete(this.UIFigure);
            else
                hide(this);
            end
        end
        
        %% pack
        function pack(this, varargin)
            % Method "pack": 
            %   
            %   "pack(this)" resizes dialog to fit its contents.  Its
            %   center does not change its location.   
            %
            %   "pack(this, 'topleft')" resizes dialog to fit its contents.
            %   Its top-left corner does not change its location.  
            fig = this.UIFigure;
            if nargin==1
                try 
                    matlab.ui.internal.PositionUtils.fitToContent(fig);
                catch
                    fitToContent(fig);
                end
            else
                try 
                    matlab.ui.internal.PositionUtils.fitToContent(fig,'topleft');
                catch
                    fitToContent(fig,'topleft');
                end
            end
        end
        
        %% destructor
        function delete(this)
            if this.IsWidgetValid
                delete(this.UIFigure);
            end
            this.UIFigure = [];
        end
        
    end
    
    %% protected methods
    methods (Access = protected)

        function buildUI(this) %#ok<*MANU>
            % Method "buildUI": 
            %
            %   "buildUI(this)"
            %
            %   Overload this method to build and assemble your dialog
            %   contents and add them to this.UIFigure.
            %   
            %   By default, it creates a 1-by-1 grid layout object.
            if this.zCreateDefaultGridLayout
                uigridlayout(this.UIFigure,[1 1]); 
            end
        end
        
        % create uifigure based dialog
        function buildDialog(this,optionalArguments)
            % "buildDialog" can be called explcitly in the constructor of
            % the sub-class if "lazy construction" is not preferred.
            % Otherwise, it is called by "show" method at the first time. 
            arguments
                this
                optionalArguments.Visible matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState('off')
                optionalArguments.WindowStyle char = 'alwaysontop'
            end
            
            % create uifigure
            this.UIFigure = uifigure('Visible', optionalArguments.Visible, 'Tag', this.Name,...
                'Name', this.Title, 'WindowStyle', optionalArguments.WindowStyle);
            % enable dark theme
            matlab.graphics.internal.themes.figureUseDesktopTheme(this.UIFigure);
            % build ui (overloaded by user)
            buildUI(this);
            % add listeners (overloaded by user)
            connectUI(this);
            % add callback to the close button at top-right of the uifigure
            this.UIFigure.CloseRequestFcn = @(ed,es) localCrossButtonClicked(this);
        end
        
    end
    
    %% Private methods
    methods (Access = private)
        
        function localCrossButtonClicked(this)
            if isvalid(this)
                if strcmp(this.CloseMode,'destroy')
                    % mode is destroy
                    if event.hasListener(this,'CloseEvent')
                        % if there is a listener, emit "CloseEvent"
                        % event.  User can use this event to approve or
                        % veto the destroy action.  User must call
                        % "delete(getWidget(dlg))" in the callback to
                        % make uifigure destroyed.
                        this.notify('CloseEvent');
                    else
                        % if there is no listener, delete uifigure
                        delete(this.UIFigure);
                    end
                else
                    % mode is cancel or hide
                    if event.hasListener(this,'CloseEvent')
                        % if there is a listener, emit "CloseEvent"
                        % event.  User can use this event to do extra
                        % actions.  User must call "hide(dlg)" in the
                        % callback to make uifigure invisible.
                        this.notify('CloseEvent');
                    else
                        % if there is no listener, hide uifigure
                        hide(this);
                    end
                end
            end
        end
        
    end
    
    %% Abstract methods
    methods(Abstract = true)
        % defined in AbstractUI but used here
        updateUI(this);
    end
    
    methods(Abstract = true, Access = protected)
        % defined in AbstractUI but used here
        connectUI(this);    
    end
    
    %% Below this line are properties and methods for QE use only
    methods (Hidden)
    
        function qeAddPackDialogListener(this, container)
            % add listener to the "PackDialog" event of a uicontainer 
            weakThis = matlab.lang.WeakReference(this);
            addlistener(container,'PackDialog',@(es,ed) qePack(weakThis.Handle));              
        end
        
        function qePack(this, varargin)
            % Mimic "pack": 
            %   
            %   "pack(this)" resizes dialog to fit its contents.  Its
            %   center does not change its location.   
            %
            %   "pack(this, 'topleft')" resizes dialog to fit its contents.
            %   Its top-left corner does not change its location.  
            pack(this, varargin{:});
            assignin('base','PackDialogFired',true);
        end
        
        function qeSelectDropDownInUITABLE(~,tbl,row,col,value,callback)
            % Mimic selecting a drop down item inside a uitable in the dialog 
            %   
            %   "qeSelectDropDownInUITABLE(this, tbl, row, col, value)"
            %   selects "value" at cell [row col] in the "tbl" object.
            %
            %   "qeSelectDropDownInUITABLE(this, tbl, row, col, value,
            %   CellEditCallback)" selects "value" at cell [row col]
            %   in the "tbl" object that triggers "CellEditCallback".  
            % 
            % Note that "value" must be part of available drop down items.
            oldvalue = tbl.Data{row,col};
            tbl.Data{row,col} = value;
            evtdata.Indices = [row col];
            evtdata.PreviousData = oldvalue;
            evtdata.EditData = value;
            evtdata.NewData = value;
            evtdata.Error = [];
            evtdata.Source = tbl;
            evtdata.EventName = 'CellEdit';
            if nargin>5
                internal.Callback.execute(callback, tbl, evtdata);
            end
        end
        
    end
    
end

function localPositionDialog_Figure(mydialog,anchor,region)
    % anchor is a figure or uifigure
    if isvalid(anchor)
        anchor_position = anchor.OuterPosition; % left, bottom, width, height
        mydialog_position = mydialog.OuterPosition;
        switch lower(region)
            case 'center'
                centerfig(mydialog,anchor);
            case 'east'
                mydialog_position(1) = anchor_position(1)+anchor_position(3)+30;
                mydialog_position(2) = anchor_position(2);
                mydialog.Position = mydialog_position;
            case 'south'
                mydialog_position(1) = anchor_position(1);
                mydialog_position(2) = anchor_position(2)-mydialog_position(4)-30;
                mydialog.Position = mydialog_position;
            case 'west'
                mydialog_position(1) = anchor_position(1)-mydialog_position(3);
                mydialog_position(2) = anchor_position(2);
                mydialog.Position = mydialog_position;
            case 'north'
                mydialog_position(1) = anchor_position(1);
                mydialog_position(2) = anchor_position(2)+anchor_position(4)+30;
                mydialog.Position = mydialog_position;
        end        
    else
        centerfig(mydialog,0);
    end
end

function localPositionDialog_UIControl(mydialog,anchor)
    % anchor is a uicontrol
    if isvalid(anchor)
        % find bottom-left corner of the uicontrol w.r.t. host figure
        pos = getpixelposition(anchor, true);
        bottom_left_uicontrol = pos(1:2);
        % find bottom-left corner of the host figure w.r.t. screen
        fig = ancestor(anchor,'figure');
        bottom_left_figure = fig.Position(1:2);
        % position dialog to the south of uicontrol
        bottom_left_anchor = bottom_left_figure + bottom_left_uicontrol;
        mydialog_position = mydialog.OuterPosition;
        mydialog_position(1) = bottom_left_anchor(1);
        mydialog_position(2) = bottom_left_anchor(2)-mydialog_position(4)-30;
        mydialog.Position = mydialog_position;
    else
        centerfig(mydialog,0);
    end
end

function positionFigureOnAppContainer(app,fig)
    %   Position a "uifigure" at the center of the AppContainer.
    %   
    %       centerfig(this, fig);
    %
    %   where "this" is an AppContainer and "fig" is a "uifigure".
    screensize = get(0,'ScreenSize');
    units = fig.Units;
    fig.Units = 'pixels';
    appsize = app.WindowBounds; % top-left = [0 0]
    appsize(2) = screensize(4) - (appsize(2)+appsize(4)); % convert to bottom-left = [0 0]
    center = [appsize(1)+appsize(3)/2 appsize(2)+appsize(4)/2];
    fig.Position = [min(max(center(1)-fig.Position(3)/2,0),screensize(3)-fig.Position(3)) min(max(center(2)-fig.Position(4)/2,0),screensize(4)-fig.Position(4)) fig.Position(3:4)];
    figure(fig);
    fig.Units = units;
end
