classdef BaseCharacteristicOptions < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
        
    properties (SetObservable, AbortSet)
        Visible     matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState(false)
    end

    properties (Hidden,GetAccess = public, SetAccess = private)
        MenuLabelText string = ""
    end
    
    properties (Access = protected)
        VisibleMenu
    end

    properties (Hidden)
        Tag
        VisibilityChangedFcn
    end
    
    methods
        function this = BaseCharacteristicOptions(optionalInputs)
            arguments
                optionalInputs.Visible matlab.lang.OnOffSwitchState = false
                optionalInputs.MenuLabel string = string.empty
                optionalInputs.Tag string = string.empty
            end
            this.Visible = optionalInputs.Visible;
            this.Tag = optionalInputs.Tag;
            this.MenuLabelText = optionalInputs.MenuLabel;
        end

        function delete(this)
            if ~isempty(this.VisibleMenu)
                delete(this.VisibleMenu);
            end
        end

        function addVisibleMenu(this,contextMenu)
            this.VisibleMenu = uimenu(contextMenu,...
                "Text",this.MenuLabelText,...
                "MenuSelectedFcn",@(es,ed) cbVisibleMenuSelected(this,es,ed),...
                "Checked",this.Visible,...
                "Tag",this.Tag);
        end

        function setMenuLabelText(this,menuLabel)
            if ~isempty(this.VisibleMenu) && isvalid(this.VisibleMenu)
                this.VisibleMenu.Text = menuLabel;
            end
            this.MenuLabelText = menuLabel;
        end

        function set.Visible(this,Visible)
            this.Visible = Visible;
            if ~isempty(this.VisibleMenu)
                this.VisibleMenu.Checked = Visible; 
            end
            if ~isempty(this.VisibilityChangedFcn) %#ok<*MCSUP>
                this.VisibilityChangedFcn(this,[]); 
            end
        end
    end

    methods (Hidden)
        function out = struct(this)
            propertyNames = fields(this);
            for k = 1:length(propertyNames)
                out.(propertyNames{k}) = this.(propertyNames{k});
            end
        end
    end

    methods(Access = private)
        function cbVisibleMenuSelected(this,es,ed)
            this.Visible = ~this.Visible;
            es.Checked = this.Visible;
        end
    end

    events
        SpecificationChanged
    end
end
