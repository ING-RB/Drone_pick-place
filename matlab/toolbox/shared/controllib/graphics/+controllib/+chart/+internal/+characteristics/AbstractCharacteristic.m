classdef AbstractCharacteristic < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
        
    properties (SetObservable, AbortSet)
        Visible     matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState(false)
    end

    properties (Access = protected)
        VisibleMenu
    end

    properties(Access=public)
        Tag
    end

    properties
        VisibilityChangedFcn
    end
    
    methods
        function this = AbstractCharacteristic(optionalInputs)
            arguments
                optionalInputs.Visible logical = false
                optionalInputs.Tag string = string.empty
            end
            this.Visible = optionalInputs.Visible;
            if isempty(optionalInputs.Tag)
                this.Tag = getDefaultTag(this);
            else
                this.Tag = optionalInputs.Tag;
            end
        end

        function delete(this)
            if ~isempty(this.VisibleMenu)
                delete(this.VisibleMenu);
            end
        end

        function addVisibleMenu(this,contextMenu)
            this.VisibleMenu = uimenu(contextMenu,...
                "Text",getMenuLabelText(this),...
                "MenuSelectedFcn",@(es,ed) cbVisibleMenuSelected(this,es,ed),...
                "Checked",this.Visible,...
                "Tag",this.Tag);
        end

        function set.Visible(this,Visible)
            this.Visible = Visible;
            this.VisibleMenu.Checked = Visible; 
            if ~isempty(this.VisibilityChangedFcn) %#ok<*MCSUP>
                this.VisibilityChangedFcn(this,[]); 
            end
        end
    end

    methods(Access = private)
        function cbVisibleMenuSelected(this,es,ed)
            this.Visible = ~this.Visible;
            es.Checked = this.Visible;
        end
    end

    methods(Access = protected)
        function tag = getDefaultTag(this)
            tag = "";
        end
    end

    methods(Abstract, Access = protected)
        menuLabelText = getMenuLabelText(this);
    end

    events
        SpecificationChanged
    end
end
