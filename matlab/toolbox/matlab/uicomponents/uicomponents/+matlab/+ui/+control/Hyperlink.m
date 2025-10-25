classdef (Sealed, ConstructOnLoad=true) Hyperlink < ...
        matlab.ui.control.internal.model.ComponentModel & ...
        matlab.ui.control.internal.model.mixin.BackgroundColorableWithNoneComponent & ...
        matlab.ui.control.internal.model.mixin.VisitedColorableComponent & ...
        matlab.ui.control.internal.model.mixin.HorizontallyAlignableComponent & ...
        matlab.ui.control.internal.model.mixin.VerticallyAlignableComponent & ...
        matlab.ui.control.internal.model.mixin.MultilineTextComponent & ...
        matlab.ui.control.internal.model.mixin.WordWrapComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent& ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipWithModeComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.FocusableComponent & ...
        matlab.ui.control.internal.model.mixin.URLComponent
%HYPERLINK Create hyperlink component
%   Hyperlink has a HyperlinkClickedFcn callback to execute MATLAB code as
%   well as a URL property to specify a file or link to open when the
%   hyperlink is clicked.  The URL value cannot start with 'matlab:'.
%
%   hlink = matlab.ui.control.Hyperlink creates a hyperlink
%   and returns the Hyperlink UI component object. No parent is created.
%
%   hlink = matlab.ui.control.Hyperlink('Parent',parent) creates a
%   hyperlink in the specified parent container.
%   The parent container can be a figure created using the uifigure
%   function, or one of its child containers: Tab, Panel, ButtonGroup or
%   GridLayout
%
%   hlink = matlab.ui.control.Hyperlink(______,Name,Value)
%   specifies Hyperlink property values using one or more
%   Name,Value pair arguments. Use this option with any of the input
%   argument combinations in the previous syntaxes.
%
%   matlab.ui.control.Hyperlink properties:
%     Hyperlink properties:
%       Text             - Hyperlink label
%       URL              - Web page address or file location
%
%     Font and Color properties:
%       FontName         -  Font name
%       FontSize         -  Font size
%       FontWeight       -  Font weight
%       FontAngle        -  Font angle
%       FontColor        -  Font color
%       BackgroundColor  -  Background color
%
%     Interactivity properties:
%       Visible          -  Hyperlink visibility
%       Enable           -  Operational state of hyperlink
%       Tooltip          -  Tooltip
%
%     Position properties:
%       Position         - Location and size
%       InnerPosition    - Location and size
%       OuterPosition    - Location and size
%       Layout           - Layout options
%
%     Callback properties:
%       HyperlinkClickedFcn  - Hyperlink clicked callback
%       CreateFcn            - Creation function
%       DeleteFcn            - Deletion function
%
%     Callback execution control properties:
%       Interruptible    - Callback interruption
%       BusyAction       - Callback queuing
%       BeingDeleted     - Deletion status
%
%     Parent/child properties:
%       Parent           - Parent container
%       Children         - Children
%       HandleVisibility - Visibility of object handle
%
%     Identifier properties:
%       Type             - Type of graphics object
%       Tag              - Object identifier
%       UserData         - User data
%
%   Example: Hyperlink that opens URL
%      fig = uifigure;
%      hlink = matlab.ui.control.Hyperlink('Parent',fig);
%      hlink.Text = 'Click Me';
%
%      % Assign Hyperlink callback in response to hyperlink being clicked
%      hlink.HyperlinkClickedFcn = @(src,event)display(event);
%
%      % Assign URL to open when hyperlink is clicked
%      hlink.URL = 'www.mathworks.com';
%
%   See also UIFIGURE, UIBUTTON, UIIMAGE, UILABEL, WEB

% Copyright 2020-2023 The MathWorks, Inc.

    properties(NonCopyable, Dependent, AbortSet)
        %HyperlinkClickedFcn - Hyperlink clicked callback.  Use this callback function to execute commands when the user clicks the hyperlink.
        HyperlinkClickedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end

    properties(NonCopyable, Access = 'private')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateHyperlinkClickedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end

    properties (Constant, Transient, Access = 'private')

        DefaultHyperlinkColor = [0, 102, 204]/256;
    end

    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})
        HyperlinkClicked;
    end
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = Hyperlink(varargin)
            %

            % Do not remove above white space
            % Override the default values

            obj.Type = 'uihyperlink';

            % Initialize Layout Properties
            defaultSize = [70, 22];
            obj.PrivateInnerPosition(3:4) = defaultSize;
            obj.PrivateOuterPosition(3:4) = defaultSize;

            obj.doSetPrivateText('Hyperlink');
            obj.FontColor_I = obj.DefaultHyperlinkColor;
            obj.doSetPrivateFontWeight('bold');

            parsePVPairs(obj,  varargin{:});

            obj.attachCallbackToEvent('HyperlinkClicked', 'PrivateHyperlinkClickedFcn');
        end

        % ----------------------------------------------------------------------
        function set.HyperlinkClickedFcn(obj, newValue)
            % Property Setting
            obj.PrivateHyperlinkClickedFcn = newValue;

            obj.markPropertiesDirty({'HyperlinkClickedFcn'});
        end

        function value = get.HyperlinkClickedFcn(obj)
            value = obj.PrivateHyperlinkClickedFcn;
        end
    end
    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)

        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.

            names = {'Text',...
                'URL',...
                'HyperlinkClickedFcn'...
                };

        end

        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = obj.Text;

        end
    end

    methods (Hidden, Static)
        function modifyOutgoingSerializationContent(sObj, obj)

            % sObj is the serialization content for obj
            modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj, obj);
            modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableWithNoneComponent(sObj, obj);
            modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.VisitedColorableComponent(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj)

            % Analyze incoming FontColor here since FontColor does not
            % match other components
            if ~sObj.hasNameValue('FontColorMode')
                legacyDefaultFontColor = matlab.ui.control.Hyperlink.DefaultHyperlinkColor;
                if isequal(sObj.getValue('FontColor'), legacyDefaultFontColor)
                    sObj.addNameValue('FontColorMode','auto');
                else
                    sObj.addNameValue('FontColorMode','manual');
                end
            end
            % sObj is the serialization content that was saved for obj
            modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj);
            modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableWithNoneComponent(sObj);
            modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.VisitedColorableComponent(sObj);
        end

    end

end
