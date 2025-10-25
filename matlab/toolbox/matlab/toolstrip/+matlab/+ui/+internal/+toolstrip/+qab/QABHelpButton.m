classdef QABHelpButton < matlab.ui.internal.toolstrip.impl.QABPushButton
    % QAB Help Button
    %
    % Constructor:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.qab.QABHelpButton.QABHelpButton">QABHelpButton</a>
    %
    % Properties: 
    %   <a href="matlab:help matlab.ui.internal.toolstrip.qab.QABHelpButton.DocName">DocName</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Component.Tag">Tag</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.mixin.CallbackFcn_ButtonPushed.ButtonPushedFcn">ButtonPushedFcn</a>
    %
    % Events: 
    %   <a href="matlab:help matlab.ui.internal.toolstrip.qab.QABHelpButton.ButtonPushed">ButtonPushed</a>
    
    % Copyright 2019-2020 The MathWorks, Inc.

    properties
        % Documentation name used to open the help viewer. If 'ButtonPushedFcn' is defined, then DocName is not used.
        % 
        % Examples:
        %     h.DocName = 'productShortName/topicId'; % '/' delimited inputs to helpview() command
        %     h.DocName = 'docName'; % input to doc() command
        DocName = '';
    end

    properties (Access = private)
        ClassAnchor = '<a href="matlab:doc matlab.ui.internal.toolstrip.qab.QABHelpButton">QABHelpButton</a>';
    end
    
    %% ----------------------------------------------------------------------------
    % Public methods
    methods
        
        %% Constructor
        function this = QABHelpButton(varargin)
            % Constructor "QABHelpButton": 
            %
            %   Create a QAB help button.
            %
            %   Examples:
            %       qabbtn = matlab.ui.internal.toolstrip.qab.QABHelpButton();
            %       qabbtn.DocName = 'productShortName/topicId'; % '/' delimited inputs to helpView() command
            %       qabbtn.DocName = 'docName'; % input to doc() command
            %       % if 'ButtonPushedFcn' is defined, then DocName is not used.
            %       qabbtn.ButtonPushedFcn = @(varargin) disp('HELP!!!');
            
            % super
            this = this@matlab.ui.internal.toolstrip.impl.QABPushButton(varargin{:});
            
            % TODO: Allow input of string to auto set the DocName, or function to auto set the ButtonPushedFcn, or struct

            this.setPropertyDefaults();
        end
        
        %% Get/Set Methods
        % DocName        
        function value = get.DocName(this)
            % GET function for DocName property.
            value = this.DocName;
        end
        function set.DocName(this, value)
            % SET function for DocName property.
            if ~ischar(value) && ~isstring(value)
                throw(MException(message('MATLAB:string')));
            end
            
            this.DocName = value;
        end
        
    end

    methods (Hidden = true)
        function openHelp(this)
            if isempty(this.DocName)
                doc;
                return;
            end
            
            tlbxSplt = strsplit(this.DocName, '/');
            if numel(tlbxSplt) > 1
                productShortName = tlbxSplt{1};
                topicId = strjoin(tlbxSplt(2:end),'/');

                try
                    % if isInMatlabOnline()
                    %     helpview(productShortName, topicId, 'CSHelpWindow');
                    % else
                        helpview(productShortName, topicId);
                    % end
                catch err
                    if isequal(err.identifier, 'MATLAB:helpview:InvalidPathArg') || ...
                       isequal(err.identifier, 'MATLAB:helpview:TopicPathDoesNotExist')
                        doc(this.DocName);
                    else
                        rethrow(err);
                    end
                end
            else
                doc(this.DocName);
            end
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

        function set_Enabled(this, ~)
            throw(MException(message('MATLAB:class:SetProhibited', 'Enabled', this.ClassAnchor)));
        end
        
        function ActionPerformedCallback(this, ~, ~)
            % Overloaded method defined in @control
            %
            if isempty(this.ButtonPushedFcn)
                this.openHelp();
            end
        end
    end

    methods (Access = private)
        function setPropertyDefaults(this)
            action = this.getAction();

            % Set Icon property
            action.Icon = matlab.ui.internal.toolstrip.Icon.HELP_16;
            action.QuickAccessIcon = matlab.ui.internal.toolstrip.Icon.HELP_16;

            % Set Text property
            action.Text = message('MATLAB:toolstrip:qab:helpLabel').getString;

            % Set Description property
            action.Description = message('MATLAB:toolstrip:qab:helpDescription').getString;

            % Set Enabled property
            action.Enabled = true;

            % Set Tag property
            this.Tag = 'QABHelpButton';
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
            else
                this.openHelp();
            end
            % fire event
            this.notify(type);
            
            
        end
     end
    
end