classdef ButtonPanel < handle & controllib.ui.internal.dialog.AbstractContainer & dynamicprops
    %% ButtonPanel - Creates a container with equal-width buttons.
    %
    %   PANEL = BUTTONPANEL(PARENT,BTNCFG) Creates a button container with
    %   the specified PARENT and BTNCFG. 
    %
    %   PARENT is a valid container object that contains the output PANEL.
    %
    %   PANEL is a grid layout that contains the buttons specifed in
    %   BTNCFG. PANEL does not provide additional padding around it and its
    %   tag value is set to "buttonLayout". PANEL Scrollable is set to
    %   false.
    %
    %   BTNCFG includes the folowing button options (specified as string):
    %   
    %   [HELP | REFRESH | ... | OK | IMPORT | EXPORT | CANCEL | CLOSE | APPLY | REVERT]
    %
    %   Note that the following group members are mutually exclusive:
    %       - [OK | IMPORT | EXPORT]
    %       - [CANCEL | CLOSE]
    %   You can specify the button options in any order, however,
    %   ButtonPanel uses a recommended predefined order. ButtonPanel
    %   creates separate properties for each BTNCFG buttons, which you can
    %   edit, e.g. to specify call back functions. The properties use
    %   "MixedCase" names. As an example, for cancel button, the property
    %   name is specified as "CancelButton".
    %
    %   BUTTONPANEL automatically creates tags for each standard button as
    %   follows:
    %       <button name in lowercase> + "Button"
    %   For example, OK button tag is "okButton".
    %
    %   PANEL = BUTTONPANEL(PARENT,BTNCFG,NAME1,VALUE1,...) Creates a
    %   button container with the following parameter NAME/VALUE pairs:
    %
    %       Supplement - Number of additional components on the left side
    %       Commit     - Number of additional components on the right side
    %   
    %   Output PANEL creates empty space for the additional supplement and
    %   commit components as follows:
    %
    %       [<BTNCFG buttons>] | <Empty space for supplement> | ... 
    %           | <Empty space for commit> | <BTNCFG buttons>] 
    %
    %   The empty space uses FIT format in PANEL.
    %
    %   ButtonPanel properties:
    %
    %       ButtonWidth - Button width in pixel value to be used for all
    %                     the buttons in BTNCFG.
    %
    %   ButtonPanel methods:
    %       None
    %
    %   Examples:
    %
    %   import controllib.widget.internal.buttonpanel.ButtonPanel    
    %
    %   %% Create a HELP-OK-CANCEL button container and specify call back functions
    %   parent = uifigure;
    %   panel = ButtonPanel(parent,["OK" "Help" "cancel"]);
    %   panel.OKButton.ButtonPushedFcn = @(s,d)disp("Ok");
    %   panel.HelpButton.ButtonPushedFcn = @(s,d)disp("Help");
    %   panel.CancelButton.ButtonPushedFcn = @(s,d)disp("Cancel");
    %
    %   %% Create additional supplement and commit components
    %   f = uifigure;
    %   parent = uigridlayout(f,[2 1]);
    %   panel = ButtonPanel(parent,["OK" "Help"],'Supplement',1,'Commit',1);
    %   btnCont = getWidget(panel);
    %   btnCont.Layout.Row = 2;
    %   btnCont.Layout.Column = 1;
    %   suppBtn = uibutton(btnCont,'Text','SuppBtn');
    %   suppBtn.Layout.Row = 1;
    %   suppBtn.Layout.Column = 2;
    %   btnCont.ColumnWidth{2} = panel.ButtonWidth;
    %   commBtn = uibutton(btnCont,'Text','CommBtn');
    %   commBtn.Layout.Row = 1;
    %   commBtn.Layout.Column = 4;
    %   btnCont.ColumnWidth{4} = panel.ButtonWidth;
    %
    %   %% Change button width to nondefault value.
    %   parent = uifigure;
    %   panel = ButtonPanel(parent,["Import" "Help" "close" "revert"]);
    %   panel.ButtonWidth = 50;
    %
    %   See also:
    %       controllib.widget.internal.buttonpanel.showcaseButtonPanel
    
    %  Copyright 2020-2022 The MathWorks, Inc.
    
    %% Properties
    properties
        %% Button width value in pixels.
        
        ButtonWidth = 80;
    end
    
    properties(SetAccess=private,GetAccess=public)
        %% Number of additonal supplement components on left side.
        Supplement
        
        %% Number of additonal commit components on right side.
        Commit
    end
    
    properties(Access=private)
        Parent
        ButtonConfig
        Layout
        LeftIndex = 0;
        RightIndex = 0;
    end
    
    %% Constructor
    methods
        function panel = ButtonPanel(parent,btnCfg,optionalArguments)
            arguments
                parent
                btnCfg string
                optionalArguments.Supplement = 0
                optionalArguments.Commit = 0
            end
            
            % Call superclass constructor.
            panel = panel@controllib.ui.internal.dialog.AbstractContainer;
            
            % Update property values.
            panel.Parent = parent;
            panel.ButtonConfig = rearrangeButtonsForVisualization(...
                    unique(lower(btnCfg)));

            panel.Supplement = optionalArguments.Supplement;
            panel.Commit = optionalArguments.Commit;
            panel.Name = 'buttonLayout';

            % Build button container.
            buildContainer(panel)
        end
    end
    
    
    %% Get/Set
    methods
        function set.ButtonWidth(panel,value)
            %% Update width of all the buttons.
            
            panel.ButtonWidth = value;
            updateLayout(panel)
        end
    end
    
    %% Protected Methods
    methods(Access=protected)
        function container = createContainer(panel)
            %% Creates the container.
            
            createLayout(panel);
            addDynamicPropertiesAndButtons(panel)
            
            % Set stretchable column in the middle of the suplement and
            % commit buttons.
            panel.Layout.ColumnWidth{panel.LeftIndex+panel.Supplement+1} = '1x';
            
            container = panel.Layout;
        end        
    end
    
    %% Private Methods
    methods(Access=private)        
        function createLayout(panel)
            %% Creates a grid layout as the button container.
            
            numComponents = numel(panel.ButtonConfig) + panel.Supplement + ...
                panel.Commit;
            panel.Layout = uigridlayout(panel.Parent,[1 numComponents+1], ...
                'Padding',0,'Scrollable',false);
            panel.Layout.RowHeight = {'fit'};            
            panel.Layout.ColumnWidth = repmat({'fit'},[1 numComponents+1]);
        end
        
        function addDynamicPropertiesAndButtons(panel)
            %% Add dynamic properties for each button.
            % A button is created as the value of each property.
            
            for btnIdx = 1:numel(panel.ButtonConfig)
                btn = panel.ButtonConfig(btnIdx);
                switch btn
                    case "help"
                        addPropertyAndButton(panel,"Help",false);
                    case "refresh"
                        addPropertyAndButton(panel,"Refresh",false);
                    case "revert"
                        addPropertyAndButton(panel,"Revert",true);
                    case "apply"
                        addPropertyAndButton(panel,"Apply",true);
                    case "close"
                        addPropertyAndButton(panel,"Close",true);
                    case "cancel"
                        addPropertyAndButton(panel,"Cancel",true);
                    case "export"
                        addPropertyAndButton(panel,"Export",true);
                    case "import"
                        addPropertyAndButton(panel,"Import",true);
                    case "ok"
                        addPropertyAndButton(panel,"OK",true);
                end
            end
        end
        
        function addPropertyAndButton(panel,prop,isCommit)
            %% Add a property and its value for a given button name.
            
            % Add property.
            propName = prop+"Button";
            p = addprop(panel,propName);
            p.SetAccess = "private";
            p.GetAccess = "public";
            
            % Add property value.
            panel.(propName) = createButton(panel,prop);
            
            % Specify button location.
            panel.(propName).Layout.Row = 1;
            if isCommit
                panel.RightIndex = panel.RightIndex + 1;
                col = length(panel.Layout.ColumnWidth) - panel.RightIndex + 1;
            else
                panel.LeftIndex = panel.LeftIndex + 1;
                col = panel.LeftIndex;
            end
            panel.(propName).Layout.Column = col;
            
            % Specify button width using the layout column width. Note that
            % button width does not work when a button is a child of a grid
            % layout.
            panel.Layout.ColumnWidth{col} = panel.ButtonWidth;
        end
        
        function btn = createButton(panel,prop)
            %% Creates a button.
            
            btn = uibutton(panel.Layout, ...
                'Text',getButtonLabel(prop), ...
                'Tag',getButtonTag(prop) ...
                );
        end
        
        function updateLayout(panel)
            %% Updates all numeric column width values using ButtonWidth.
            
            % Standard supplement buttons.
            for idx = 1:panel.LeftIndex
                panel.Layout.ColumnWidth{idx} = panel.ButtonWidth;
            end

            % Standard commit buttons.
            n = length(panel.Layout.ColumnWidth);
            for idx = 1:panel.RightIndex
                col = n - idx + 1;
                panel.Layout.ColumnWidth{col} = panel.ButtonWidth;
            end
        end
    end    
end
%% Local functions --------------------------------------------------------
function btnLabel = getButtonLabel(name)
%% Get button label from message catalog.

msgCatalogId = "Controllib:gui:str" + name;
btnLabel = getString(message(msgCatalogId));
end

function tag = getButtonTag(name)
%% Specifies button tag.

tag = lower(name) + "Button";
end

function orderedCfg = rearrangeButtonsForVisualization(cfg)
%% Rearrange the buttons according to the recommended order.

orderedCfg = cfg;
buttonOrder = ["help" "refresh" "revert" "apply" "close" "cancel" "export" ...
    "import" "ok"];
idx = 1;
for btn = buttonOrder
    id = cfg.contains(btn);
    if any(id)
        orderedCfg(idx) = btn;
        idx = idx + 1;
        cfg(id) = [];
    end
end
end