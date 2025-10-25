classdef MixedInContainer < handle
    % MixedIn class that wraps a uicontainer widget such as uipanel,
    % uigridlayout, uitabgroup, Accordion, etc.
    %
    % Subclass it to define a UI component shared among different dialogs.
    
    % Author(s): Rong Chen
    % Copyright 2019 The MathWorks, Inc.
    
    %% Public properties
    properties (Dependent)
        % Property "Name": 
        %   uicontainer id, must be a string
        Name
    end
    
    properties (Access = private)
        % Name
        pName = ''
    end
    
    properties (Dependent, SetAccess = private)
        % Property "IsWidgetValid": 
        %   true if uicontainer exists and is valid
        IsWidgetValid
    end
    
    %% Protected properties
    properties(Access = protected, Transient)
        % Reference to a uicontainer
        Container
    end
    
    %% Events
    events
        % Event "PackDialog": 
        %   request hosting dialog to pack (resize)
        PackDialog
    end
    
    %% Public methods
    methods
        
        %% getters and setters
        % Name (corresponds to uicontainer.Tag)
        function value = get.Name(this)
            value = this.pName;
        end
        function set.Name(this, value)
            this.pName = value;
            if this.IsWidgetValid
                this.Container.Tag = value;
            end
        end
        % IsWidgetValid (true if uicontainer exists and is valid)
        function value = get.IsWidgetValid(this)
            value = ~isempty(this.Container) && isvalid(this.Container);
        end
        
        %% get uicontainer
        function obj = getWidget(this)
            % Method "getWidget": 
            %   obj = getWidget(this) returns the handle of uicontainer.
            %   The method builds the uicontainer if it doesn't exist.
            if ~this.IsWidgetValid
                buildContainer(this);
            end
            obj = this.Container;
        end
        
        %% destructor
        function delete(this)
            % delete uicontainer
            if this.IsWidgetValid
                delete(this.Container);
            end
            this.Container = [];
            % make sure QEDialog gets destroyed too
            if this.qeIsDialogValid()
                delete(this.QEDialog);
            end
        end
        
    end
    
    %% Protected methods
    methods (Access = protected)
    
        function obj = createContainer(this) %#ok<*MANU>
            % Method "createContainer": 
            %
            %   Create a uicontainer object without a parent.  
            %
            %   obj = createContainer(this)
            %
            % By default, it returns a uipanel object.  
            %
            % The method should be overloaded by subclass.
            obj = uipanel('Parent',[]);
            uilabel(obj,'Text','Overload "createContainer"','Position',[1 1 200 20]);
        end
        
        function buildContainer(this)
            % Method "buildContainer": 
            %
            % "buildContainer" can be called explcitly in the constructor
            % of the sub-class for "instant construction".  Otherwise,
            % "getWidget" should be called in the "buildUI" method of the
            % host dialog class for "lazy construction".

            % create uicontainer
            obj = createContainer(this);
            if contains(class(obj),'matlab.ui.container')
                % it must be a valid container class
                this.Container = obj;
                this.Container.Tag = this.Name;
                % add listeners
                connectUI(this);
            else
                error('"createContainer" must return a "matlab.ui.container.***" object')
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
    properties(Access = private)
        % dialog for hosting the uicontainer
        QEDialog
    end
    
    methods (Hidden)
        
        function dlg = qeGetDialog(this)
            dlg = this.QEDialog;
        end
        
        function value = qeIsDialogValid(this)
            value = ~isempty(this.QEDialog) && this.QEDialog.IsWidgetValid;
        end
        
        function qeShow(this, varargin)
            if ~this.qeIsDialogValid()
                % build dialog
                dlg = controllib.ui.internal.dialog.AbstractDialog();
                dlg.Name = ['QEDialog_' this.Name];
                dlg.Title = this.Name;
                dlg.zCreateDefaultGridLayout = false;
                % render
                show(dlg, varargin{:});
                % replace panel and pack dialog
                if ~this.IsWidgetValid
                    buildContainer(this);
                end
                qeAddPackDialogListener(dlg,this);
                this.Container.Parent = getWidget(dlg);
                % save handle
                this.QEDialog = dlg;
            end
            % update uicontainer
            updateUI(this);
        end
        
    end
    
end