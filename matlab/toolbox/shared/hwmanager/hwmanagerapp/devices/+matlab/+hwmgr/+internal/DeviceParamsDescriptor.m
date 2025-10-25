classdef DeviceParamsDescriptor < matlab.mixin.Heterogeneous ...
        & matlab.hwmgr.internal.DialogMixin ...
        & matlab.hwmgr.internal.AppContainerAccessMixin
    % This class allows hardware manager teams to define the params to
    % collect via a modal toolstrip tab

    % Copyright 2018-2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        %NAME
        %   This is the user visible name of the constructor whose
        %   parameters are being colected
        Name
    end

    properties(GetAccess = public, SetAccess = ?matlab.hwmgr.internal.DeviceProviderBase)
        % The parent device provider
        Provider
    end

    % Properties with access to ProtocolTabHandler, this class, and subclasses
    properties (Access = {?matlab.hwmgr.internal.hwmanagerapp.modules.ToolStrip.ProtocolTabHandler, ...
            ?matlab.hwmgr.internal.DeviceParamsDescriptor})
        %PARAMDESCRIPTORMAP
        %   This is a map of the parameters to param attributes such as
        %   user visible label, type, allowed values function and enable
        %   function
        ParamDescriptorMap containers.Map

        %PARAMCOUNTER
        %   A variable counting the number of parameters added so far
        ParamCounter (1,1) double

        %MAPFILE
        %   Path to the map file for the CSH page to be shown in hardware
        %   manager while the user is entering paramaters
        MapFile (1,1) string

        %TOPICID
        %   The topic ID for the page to be shown in hardware manager
        %   while the user is entering parameters
        TopicID (1,1) string

    end

    properties (GetAccess = public)

        %BUTTONENABLE
        %   A boolean flag that is used to enable/disable a button on
        %   the toolstrip
        ButtonEnable (1,1) logical

        %ButtonTooltipText
        %   A string representing the tooltip text to display on the
        %   button
        ButtonTooltipText (1,1) string
    end

    properties (Hidden, SetAccess = {?matlab.hwmgr.internal.toolstrip.ParamTabHandler, ?tDeviceParamDescriptor, ?tParamTabHandler})
        % Detected Device using the DeviceParamsDescriptor, if applicable
        CurrentDevice (1,1)

        % Dictionary of column properties with key: Section name + "_" +
        % Column number
        ColumnProp dictionary =  configureDictionary("string","struct")
    end

    methods (Abstract)
        % These are the abstract methods that need to be implemented by
        % client teams

        %VALIDATEPARAMS
        %   Implement this method to check the paramMap containing the
        %   values entered and confirmed by the user for use in the
        %   constructor
        validateParams(obj, paramMap)

        % IMPLEMENT at least one of these two functions depending on whether
        % creating a non-enumerable device or configuring an existing device

        %DEVICE = CREATEHWMGRDEVICE
        %   Implement this method to use the param values in the paramMap
        %   to create a hardware manager device, set it's properties and
        %   return it. The underlying client specific constructor does not
        %   have to be created. It is suggested that the paramMap be
        %   cached for later use in the hardware manager device object.
        device = createHwmgrDevice(obj, paramMap)


        %DEVICE = CONFIGUREHWMGRDEVICE
        %   Implement this method to use the param values in the paramMap
        %   to configure a hardware manager device, set it's properties and
        %   return it. It is suggested that the paramMap be
        %   cached for later use in the hardware manager device object.
        %   device = configureHwmgrDevice(obj, oldDevice, paramMap)

        %ICON = GETICON
        %   Implement this method to return IconID to use as the icon for
        %   the button shown in the non-enumerable device gallery on the
        %   main hardware manager tab
        icon = getIcon(obj)

    end

    methods
        % CONSTRUCTOR
        function obj = DeviceParamsDescriptor(name, varargin)
            p = inputParser;
            p.addRequired('Name', @(x)ischar(x) || isstring(x));

            p.addOptional('MapFile', '',  @(x)ischar(x) || isstring(x));
            p.addOptional('TopicID', '', @(x)ischar(x) || isstring(x));
            p.addOptional('ButtonTooltipText', '', @(x)ischar(x) || isstring(x));
            p.addOptional('ButtonEnable', true, @(x)islogical(x));

            p.parse(name, varargin{:});

            if xor(isempty(p.Results.MapFile), isempty(p.Results.TopicID))
                error('Both MapFile and TopicID must be defined');
            end

            obj.Name = name;
            obj.MapFile = p.Results.MapFile;
            obj.TopicID = p.Results.TopicID;
            obj.ButtonTooltipText = p.Results.ButtonTooltipText;
            obj.ButtonEnable = p.Results.ButtonEnable;


            obj.ParamDescriptorMap = containers.Map();
            obj.ParamCounter = 0;
        end

        function device = createAndInitDevice(obj, paramValMap)
            device = obj.createHwmgrDevice(paramValMap);
            device.IsNonEnumerable = true;
            device.Descriptor = class(obj);
            device.ProviderClass = class(obj.Provider);
        end

        % Client apps must OVERRIDE this function, if this DeviceParamsDescriptor
        % will be used to configure a detected device
        function device = configureHwmgrDevice(obj, oldDevice, paramMap)
            device = oldDevice;
        end

        %NAME = GETNAME
        %   Returns the user visible name string of the
        %   non-enumerable device constructor
        function name = getName(obj)
            name = obj.Name;
        end

        function mapFile = getMapFile(obj)
            mapFile = obj.MapFile;
        end

        function topicID = getTopicID(obj)
            topicID = obj.TopicID;
        end

        function text = getButtonTooltipText(obj)
            text = obj.ButtonTooltipText;
        end

        function bool = hasHelpPage(obj)
            bool = ~isempty(obj.MapFile) && ~isempty(obj.TopicID);
        end


        %ID = GETGALLERYBUTTONTAG
        %   Returns an unique id for the device that is constructed based
        %   on the name of the class on which this method is invoked
        %   appended by a string "_ID" to it.
        function id = getGalleryButtonTag(obj)
            clName = class(obj);
            id = strcat(clName, '_ID');
        end

        %ADDPARAMETER(PARAMID, PARAMNAME, WIDGETTYPE, ALLOWEDVALUESFCN,
        %ENABLEFCN, SECTIONLABEL)
        %   This method allows the client to describe a parameter to
        %   collect values for via the Parameter Toolstrip Tab
        %
        %   PARAMID     - a string that allows the parameter to be
        %                 identified in the param value map passed in to
        %                 each of the allowedValueFcns and enableFcns
        %
        %   PARAMNAME   - a user visible string used as the label for the
        %                 field shown to the user in the param toolstrip
        %                 tab
        %
        %   WIDGETTYPE  - Can be one of the following:
        %                 {"DropDown", "EditableDropDown" , "EditField", "NonEditableField", "CheckBox"}
        %
        %   AV = ALLOWEDVALUESFCN(PVMAP)
        %               - A function handle that is
        %                 invoked every time one of the parameters are
        %                 modified by the user on the toolstrip. The
        %                 function is expected to return a list of
        %                 allowed values AV for the parameter
        %                 identified by PARAMID. PVMAP is the
        %                 parameter value map containing the parameter
        %                 values entered by the user where the keys
        %                 are PARAMIDs. The PVMAP value is a struct
        %                 which fields NewValue and OldValue. If the
        %                 new and old values are different, that
        %                 means the parameter was just modified by
        %                 the user.
        %
        %                 If WIDGETTYPE is "DropDown" then the
        %                 returned allowed values are used as drop
        %                 down menu items.
        %
        %                 If WIDGETTYPE is "EditField" then the
        %                 function can optionally return a single
        %                 value which will be used as a default value
        %                 in the editfield. Otherwise, the function
        %                 can simply be function_handle.empty
        %
        %                 If WIDGETTYPE is "CheckBox" then the
        %                 function can optionally return a single
        %                 logical value which will be used as a default value
        %                 in the checkBox (true for checked and false for
        %                 unchecked). Otherwise, the function
        %                 can simply be function_handle.empty
        %
        %   BOOL = ENABLEFCN(PARAMVALMAP)
        %               - A function handle that is invoked every time
        %                 one of the parameters are modified by the
        %                 user on the toolstrip. The function is
        %                 expected to return a logical true or false
        %                 to enable or disable the widget for the
        %                 parameter.
        %
        %   SECTIONLABEL - A user visible string label for the tab section
        %                  in which the paramater will be shown
        %
        %   OPTIONAL N-V ARGUMENTS
        %
        %   DESCRIPTION
        %           - A user visible tooltip for the parameter
        %
        %   COLUMNNUM
        %           - The column within a section that the elements should
        %             reside in. It is used to skip columns before it is
        %             filled with 3 elements by default
        function addParameter(obj, varargin)
            % Parse the input
            p = inputParser();
            p.CaseSensitive = false;
            p.addRequired('ParamID', @(x) ischar(x) && ~isempty(x));
            p.addRequired('ParamName', @(x) ischar(x) && ~isempty(x));
            p.addRequired('Type', @(x)strcmp(x,'DropDown') || strcmp(x, 'EditField') || strcmp(x, 'NonEditableField') || strcmp(x, 'EditableDropDown') || strcmp(x, 'CheckBox'));
            p.addRequired('AllowedValuesFcn', @(x)validateattributes(x, {'function_handle'}, {}));
            p.addRequired('EnableFcn', @(x)validateattributes(x, {'function_handle'}, {}));
            p.addRequired('SectionLabel', @(x) ischar(x) && ~isempty(x));
            p.addParameter('Description', "", @(x) ischar(x) || isstring(x));
            p.addParameter('ColumnNum', [], @(x) validateattributes(x,{'numeric'},{'integer','positive'}));
            p.parse(varargin{:});

            % Cache the results of parsing as the paramStruct to be used in
            % the param descriptor map
            obj.addParamImpl(p.Results);

        end

        %ADDBUTTON(PARAMID, LABEL, ICON, STYLE, BUTTONPUSHEDFCN, ENABLEFCN,
        %SECTIONLABEL)
        %
        %   This method allows the client to describe a button to be shown
        %   in a section on the modal tab
        %
        %
        %   PARAMID - a string that identifies the button and serves as the
        %            key to be used in the param-value map passed to each
        %            of the allowedValueFcns, enableFcns and callback
        %            functions
        %
        %   LABEL   - The label string shown on the button
        %
        %   ICON    - An icon id from the icon id catalog to be used
        %             as the icon for the button
        %
        %   STYLE   - This can be one the following values:
        %             {'Horizontal', 'Vertical'}
        %
        %   VAL = BUTTONPUSHEDFCN(PARAMVALMAP)
        %           - This is the callback function to be invoked
        %             when the button is clicked. The callback
        %             function should take one input argument that
        %             is the param-value struct and return one
        %             value that can be accessed by other parameter
        %             callbacks
        %
        %   BOOL = ENABLEFCN(PARAMVALMAP)
        %           - A function handle that is invoked every time
        %             one of the parameters are modified by the
        %             user on the toolstrip. The function is
        %             expected to return a logical true or false
        %             to enable or disable the widget for the
        %             parameter.
        %
        %   SECTIONLABEL
        %           - A user visible string label for the tab
        %             section in which the paramater will be shown
        %
        %   OPTIONAL N-V ARGUMENTS
        %
        %   DESCRIPTION
        %           - A user visible tooltip for the button
        %
        %   COLUMNNUM
        %           - The column within a section that the elements should
        %             reside in. It is used to skip columns before it is
        %             filled with 3 elements by default
        function addButton(obj, varargin)
            p = inputParser();
            p.CaseSensitive = false;
            p.addRequired('ParamID', @(x) ischar(x) && ~isempty(x));
            p.addRequired('Label', @(x) ischar(x) && ~isempty(x));
            p.addRequired('Icon', @(x)validateattributes(x, {'matlab.ui.internal.toolstrip.Icon', 'char', 'string'}, {}));
            p.addRequired('Style',  @(x)strcmp(x,'Horizontal') || strcmp(x, 'Vertical'));
            p.addRequired('ButtonPushedFcn', @(x)validateattributes(x, {'function_handle'}, {}));
            p.addRequired('EnableFcn', @(x)validateattributes(x, {'function_handle'}, {}));
            p.addRequired('SectionLabel', @(x) ischar(x) && ~isempty(x));
            p.addParameter('Description', "", @(x) ischar(x) || isstring(x));
            p.addParameter('ColumnNum', [], @(x) validateattributes(x,{'numeric'},{'integer','positive'}));
            p.parse(varargin{:});

            paramStruct = p.Results;
            paramStruct.Type = 'PushButton';
            paramStruct.AllowedValuesFcn = function_handle.empty;

            obj.addParamImpl(paramStruct);
        end

        %ADDEMPTYPARAMETER(SECTIONLABEL)
        %
        %   This method allows the client to add an empty parameter in the
        %   Section specified, with the optional N-V pair for Column number
        %
        %   SECTIONLABEL
        %           - A user visible string label for the tab
        %             section in which the paramater will be shown
        %
        %   OPTIONAL N-V ARGUMENTS
        %
        %   COLUMNNUM
        %           - The column within a section that the elements should
        %             reside in. It is used to skip columns before it is
        %             filled with 3 elements by default
        function addEmptyParameter(obj, varargin)
            p = inputParser();
            p.CaseSensitive = false;
            p.addRequired('SectionLabel', @(x) ischar(x) && ~isempty(x));
            p.addParameter('ColumnNum', [], @(x) validateattributes(x,{'numeric'},{'integer','positive'}));
            p.parse(varargin{:});

            paramStruct = p.Results;
            paramStruct.Type = "EmptyControl";
            % Set the ParamID of EmptyControl to a unique paramID
            paramStruct.ParamID = "EmptyControl_" + obj.ParamCounter+1;
            obj.addParamImpl(paramStruct);
        end

        %SETCOLUMNPROPERTY(SECTIONLABEL, COLUMNNUM)
        %
        %   This method allows the client to modify the properties of a
        %   column within a section
        %
        %   SECTIONLABEL
        %           - A user visible string label for the tab
        %             section in which the paramater will be shown
        %   COLUMNNUM
        %           - The column number within a section for which to
        %           modify the properties
        %
        %   OPTIONAL N-V ARGUMENTS
        %
        %   HORIZONTALALIGNMENT
        %           - The horizontal alignment of the field column for
        %           parameters and for horizontal buttons, "left" will
        %           place the element in the label column, while the default
        %           "right" will place the element in the field column
        %
        %   WIDTH
        %           - The width of the column in pixels. The default is 100
        function setColumnProperty(obj, varargin)
            p = inputParser();
            p.CaseSensitive = false;
            p.addRequired('SectionLabel', @(x) ischar(x) && ~isempty(x));
            p.addRequired('ColumnNum', @(x) validateattributes(x,{'numeric'},{'integer','positive'}));
            p.addParameter('HorizontalAlignment', "right",  @(x) any(validatestring(x, {'right','center','left'})));
            p.addParameter('Width', 100, @(x) validateattributes(x,{'numeric'},{'integer','positive'}));
            p.parse(varargin{:});
            val.HorizontalAlignment = p.Results.HorizontalAlignment;
            val.Width = p.Results.Width;
            key = p.Results.SectionLabel +"_" + p.Results.ColumnNum;
            obj.ColumnProp(key) = val;
        end

    end

    methods (Access = private)

        function addParamImpl(obj, paramStruct)
            % Check to see if the parameter was already added
            paramIds = obj.ParamDescriptorMap.keys();
            if ismember(paramStruct.ParamID, paramIds)
                error('hwmanagerapp:framework:DeviceParamAlreadyAdded',paramStruct.ParamID);
            end

            % Increment the ParamCounter
            obj.ParamCounter = obj.ParamCounter + 1;

            % Add the index field so that the parameters are shown in the
            % order they are added
            paramStruct.ParamIndex = obj.ParamCounter;

            % Store the parameter in the param descriptor map
            obj.ParamDescriptorMap(paramStruct.ParamID) = paramStruct;
        end

    end

    methods (Access = {?matlab.hwmgr.internal.toolstrip.ParamTabHandler, ?tDeviceParamDescriptor, ?tParamTabHandler})
        function p = getParamDescriptorMap(obj)
            p = obj.ParamDescriptorMap;
        end
    end

    methods (Hidden)

        function outStruct = toDeviceCardStruct(obj)
            % This method is used to construct the struct to be sent to
            % device list JS for display on descriptor card.
            
            outStruct.DeviceTypeIconID = obj.getIcon();
            outStruct.TitleText = obj.Name;

            outStruct.Enabled = obj.ButtonEnable;
            outStruct.TooltipText = obj.ButtonTooltipText;
        end
    end
end
