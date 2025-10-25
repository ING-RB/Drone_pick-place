classdef QABPushButton < matlab.ui.internal.toolstrip.impl.QABPushButton
    % QAB Button
    %
    % Constructor:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.qab.QABPushButton.QABPushButton">QABPushButton</a>
    %
    % Properties:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Control.Enabled">Enabled</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Control.Description">Description</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.mixin.ActionBehavior_Text.Text">Text</a>       
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Component.Tag">Tag</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.mixin.CallbackFcn_ButtonPushed.ButtonPushedFcn">ButtonPushedFcn</a>
    %
    %
    % Events:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.qab.QABPushButton.ButtonPushed">ButtonPushed</a>

    % Copyright 2020 The MathWorks, Inc.

    properties (Access = private)
        ClassAnchor = '<a href="matlab:doc matlab.ui.internal.toolstrip.qab.QABPushButton">QABPushButton</a>';
    end

    %% ----------------------------------------------------------------------------
    % Public methods
    methods

        %% Constructor
        function this = QABPushButton(varargin)
            % Constructor "QABPushButton":
            %
            %   Create a QAB button.
            %
            %   Examples:
            %       qabbtn = matlab.ui.internal.toolstrip.qab.QABPushButton();
            %       qabbtn.ButtonPushedFcn = @(varargin) disp('QAB Button called!');

            % super
            this = this@matlab.ui.internal.toolstrip.impl.QABPushButton(varargin{:});

            % TODO: Allow input of a function to auto set the ButtonPushedFcn, or logical to auto set Enabled, or struct

        end
   
    end
  
    %% You must put all the overloaded methods here
    methods (Access = protected)

        function set_Icon(this, icon)
            action = this.getAction();

            action.Icon = icon;
            action.QuickAccessIcon = icon;
        end

        function set_IconOverride(this, ~)
            throw(MException(message('MATLAB:class:SetProhibited', 'IconOverride', this.ClassAnchor)));
        end

        function set_QuickAccessIcon(this, ~)
            throw(MException(message('MATLAB:class:SetProhibited', 'QuickAccessIcon', this.ClassAnchor)));
        end

        function set_TextOverride(this, ~)
            throw(MException(message('MATLAB:class:SetProhibited', 'TextOverride', this.ClassAnchor)));
        end

        function set_DescriptionOverride(this, ~)
            throw(MException(message('MATLAB:class:SetProhibited', 'DescriptionOverride', this.ClassAnchor)));
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