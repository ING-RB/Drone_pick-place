classdef QABUndoButton < matlab.ui.internal.toolstrip.impl.QABPushButton
    % QAB Undo Button
    %
    % Constructor:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.qab.QABUndoButton.QABUndoButton">QABUndoButton</a>     
    %
    % Properties: 
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Control.Enabled">Enabled</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Component.Tag">Tag</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.mixin.CallbackFcn_ButtonPushed.ButtonPushedFcn">ButtonPushedFcn</a>
    %
    % Events: 
    %   <a href="matlab:help matlab.ui.internal.toolstrip.qab.QABUndoButton.ButtonPushed">ButtonPushed</a>
    
    % Copyright 2019-2020 The MathWorks, Inc.

    properties (Access = private)
        ClassAnchor = '<a href="matlab:doc matlab.ui.internal.toolstrip.qab.QABUndoButton">QABUndoButton</a>';
    end
    
    %% ----------------------------------------------------------------------------
    % Public methods
    methods
        
        %% Constructor
        function this = QABUndoButton(varargin)
            % Constructor "QABUndoButton": 
            %
            %   Create a QAB undo button.
            %
            %   Examples:
            %       qabbtn = matlab.ui.internal.toolstrip.qab.QABUndoButton();
            %       qabbtn.ButtonPushedFcn = @(varargin) disp('Undo called!');
            
            % super
            this = this@matlab.ui.internal.toolstrip.impl.QABPushButton(varargin{:});
            
            % TODO: Allow input of a function to auto set the ButtonPushedFcn, or logical to auto set Enabled, or struct

            this.setPropertyDefaults();
        end
        
    end
    
    %% You must put all the overloaded methods here
    methods (Access = protected)

        function set_Icon(this, ~)
            throw(MException(message('MATLAB:class:SetProhibited', 'Icon', this.ClassAnchor)));
        end

        function set_IconOverride(this, ~)
            throw(MException(message('MATLAB:class:SetProhibited', 'IconOverride', this.ClassAnchor)));
        end

        function set_QuickAccessIcon(this, ~)
            throw(MException(message('MATLAB:class:SetProhibited', 'QuickAccessIcon', this.ClassAnchor)));
        end

        function set_Text(this, ~)
            throw(MException(message('MATLAB:class:SetProhibited', 'Text', this.ClassAnchor)));
        end

        function set_TextOverride(this, ~)
            throw(MException(message('MATLAB:class:SetProhibited', 'TextOverride', this.ClassAnchor)));
        end

        function set_Description(this, ~)
            throw(MException(message('MATLAB:class:SetProhibited', 'Description', this.ClassAnchor)));
        end

        function set_DescriptionOverride(this, ~)
            throw(MException(message('MATLAB:class:SetProhibited', 'DescriptionOverride', this.ClassAnchor)));
        end
        
    end

    methods (Access = private)
        function setPropertyDefaults(this)
            action = this.getAction();

            % Set Icon property
            action.Icon = matlab.ui.internal.toolstrip.Icon.UNDO_16;
            action.QuickAccessIcon = matlab.ui.internal.toolstrip.Icon.UNDO_16;

            % Set Text property
            action.Text = message('MATLAB:toolstrip:qab:undoLabel').getString;

            % Set Description property
            action.Description = message('MATLAB:toolstrip:qab:undoDescription').getString;

            % Set Enabled property
            action.Enabled = false;

            % Set Tag property
            this.Tag = 'QABUndoButton';
        end
    end
    
    methods (Hidden)
        function qePushed(this)
            % qeButtonPushed(this) mimics user pushes the
            % button in the UI.  "ButtonPushed" event is fired.
            type = 'ButtonPushed';
            % call ButtonPushedFcn if any
            if ~isempty(this.ButtonPushedFcn)
                internal.Callback.execute(this.ButtonPushedFcn, getAction(this));
            end
            % fire event
            this.notify(type);
            
            
        end
     end
    
end