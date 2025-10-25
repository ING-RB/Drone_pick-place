classdef UicontrolConversionUtils
    %UICONTROLCONVERSIONUTILS Common code to help convert properties set on a uicontrol
    %   to properties on uicomponents.  Used by the GUIDE to App Designer migration
    %   tool and the uicontrol redirect.  When updating this file any impact on these
    %   tools must be taken into account.

    % Copyright 2019-2022 The MathWorks, Inc.

    properties (Constant)
        CallbackPropertyNames = {...
            'ButtonDownFcn' ,...
            'Callback'      ,...
            'CreateFcn'     ,...
            'DeleteFcn'     ,...
            'KeyPressFcn'   ,...
            'KeyReleaseFcn', ...
            };

        PropertyConversionFunctionPairs = matlab.ui.internal.componentconversion.UicontrolConversionUtils.buildPropertyConversionFunctionPairs();

        PropertyConversionFunctions = matlab.ui.internal.componentconversion.UicontrolConversionUtils.buildPropertyConversionFunctionMap();
    end

    methods (Static)
        function componentCreationFunction = getComponentCreationFunction(guideComponent)
            switch guideComponent.Style
                case 'checkbox'
                    componentCreationFunction = @uicheckbox;
                case 'edit'
                    if (guideComponent.Max - guideComponent.Min) > 1
                        componentCreationFunction = @uitextarea;
                    else
                        componentCreationFunction = @uieditfield;
                    end
                case 'frame'
                    % Frame was deprecated in 2006a.
                    componentCreationFunction = [];
                case 'listbox'
                    componentCreationFunction = @uilistbox;
                case 'popupmenu'
                    componentCreationFunction = @uidropdown;
                case 'pushbutton'
                    componentCreationFunction = @uibutton;
                case 'radiobutton'
                    componentCreationFunction = @uiradiobutton;
                case 'slider'
                    componentCreationFunction = @uislider;
                case 'text'
                    componentCreationFunction = @uilabel;
                case 'togglebutton'
                    % TODO: need to handle buttons in a button group
                    componentCreationFunction = @uibutton;
                otherwise
                    % Fail safe for unrecognized uicontrol
                    error('uicontrol:conversion:UnsupportedUicontrolStyle', guideComponent.Style);
            end
        end

        function propertyValuePairs = getComponentCreationPropertyValuePairs(guideComponent)
            % Create the appropriate App Designer Component
            switch guideComponent.Style
                case 'text'
                    % GUIDE text component is alwasy vertically aligned to
                    % the top. Need to set the uilabel vertical alignment
                    % to match.
                    % Set the WordWrap property to enable the string to
                    % wrap in the view.
                    propertyValuePairs = {'WordWrap', 'on', 'VerticalAlignment', 'top'};
                case 'togglebutton'
                    propertyValuePairs = {'state'};
                otherwise
                    propertyValuePairs = {};
            end
        end

        function propertyValuePairs = getPVPairsToMimicLookAndFeel(guideComponent)
            import matlab.ui.internal.componentconversion.UicontrolConversionUtils;
            propertyValuePairs = UicontrolConversionUtils.getComponentCreationPropertyValuePairs(guideComponent);
        end

        function callbackPropertyNames = getCallbackPropertyNames()
            import matlab.ui.internal.componentconversion.UicontrolConversionUtils;
            callbackPropertyNames = UicontrolConversionUtils.CallbackPropertyNames;
        end

        function conversionFuncs = getPropertyConversionFunctions()
            conversionFuncs = matlab.ui.internal.componentconversion.UicontrolConversionUtils.PropertyConversionFunctionPairs;
        end

        function conversionFuncPairs = buildPropertyConversionFunctionPairs()
            import matlab.ui.internal.componentconversion.UicontrolConversionUtils;
            import matlab.ui.internal.componentconversion.BasePropertyConversionUtil;

            conversionFuncPairs = {...
                {'BackgroundColor'    , @UicontrolConversionUtils.convertBackgroundColor},...
                {'BusyAction'         , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'ButtonDownFcn'      , @BasePropertyConversionUtil.noopConversionFunction},...
                {'CData'              , @UicontrolConversionUtils.convertCData},...
                {'ContextMenu'        , @BasePropertyConversionUtil.noopConversionFunction},...
                {'CreateFcn'          , @BasePropertyConversionUtil.noopConversionFunction},...
                {'DeleteFcn'          , @BasePropertyConversionUtil.noopConversionFunction},...
                {'Enable'             , @UicontrolConversionUtils.convertEnable},...
                {'FontAngle'          , @BasePropertyConversionUtil.convertFontAngle},...
                {'FontName'           , @BasePropertyConversionUtil.convertFontName},...
                {'FontSize'           , @BasePropertyConversionUtil.convertFontSize},...
                {'FontUnits'          , @UicontrolConversionUtils.convertFontUnits},...
                {'FontWeight'         , @BasePropertyConversionUtil.convertFontWeight},...
                {'ForegroundColor'    , @UicontrolConversionUtils.convertForegroundColor},...
                {'HandleVisibility'   , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'HitTest'            , @BasePropertyConversionUtil.noopConversionFunction},...
                {'HorizontalAlignment', @UicontrolConversionUtils.convertHorizontalAlignment},...
                ... % Don't want to set interruptible on uicontrol's backing uicomponent,
                ... % otherwise the uicontrol's callback may not be run.
                {'Interruptible'      , @BasePropertyConversionUtil.noopConversionFunction},...
                {'KeyPressFcn'        , @BasePropertyConversionUtil.noopConversionFunction},...
                {'KeyReleaseFcn'      , @BasePropertyConversionUtil.noopConversionFunction},...
                {'ListboxTop'         , @UicontrolConversionUtils.convertListboxTop},...
                {'Max'                , @UicontrolConversionUtils.convertMaxAndMin},...
                {'Min'                , @UicontrolConversionUtils.convertMaxAndMin},...
                {'Position'           , @UicontrolConversionUtils.convertPosition},...
                {'Selected'           , @BasePropertyConversionUtil.noopConversionFunction}...
                {'SelectionHighlight' , @BasePropertyConversionUtil.noopConversionFunction}...
                {'SliderStep'         , @UicontrolConversionUtils.convertSliderStep},...
                {'String'             , @UicontrolConversionUtils.convertString}...
                {'Tag'                , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'TooltipString'      , @BasePropertyConversionUtil.convertTooltipString},...
                {'UIContextMenu'      , @BasePropertyConversionUtil.noopConversionFunction},...
                {'UserData'           , @BasePropertyConversionUtil.convertUserData},...
                {'Units'              , @UicontrolConversionUtils.convertUnits},...
                {'Visible'            , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'Value'              , @UicontrolConversionUtils.convertValue}...
                };
        end

        function conversionFuncMap = buildPropertyConversionFunctionMap()
            import matlab.ui.internal.componentconversion.UicontrolConversionUtils;

            propertyConversionFunctions = UicontrolConversionUtils.getPropertyConversionFunctions();

            % flatten the nested cell arrays into a list of key-value pairs,
            % which dictionary's constructor can take directly
            pairs = [propertyConversionFunctions{:}];
            conversionFuncMap = dictionary(pairs{:});
        end

        function pvPairs = convertProperty(uicontrolModel, propName)
            % Don't convert properties that are not present in the map
            % of property conversion functions. Converting properties that
            % are not in the map can lead to errors or unexpected behavior.
            import matlab.ui.internal.componentconversion.UicontrolConversionUtils;
            if isKey(UicontrolConversionUtils.PropertyConversionFunctions, propName)
                conversionFcn = UicontrolConversionUtils.PropertyConversionFunctions(propName);
                pvPairs = conversionFcn(uicontrolModel, propName);
            else
                pvPairs = [];
            end
        end

        function pvp = convertBackgroundColor(guideComponent, prop)

            import matlab.ui.internal.componentconversion.BasePropertyConversionUtil;

            pvp = [];

            switch guideComponent.Style
                case {'pushbutton', 'text', 'togglebutton', 'frame', 'slider'}
                    pvp = BasePropertyConversionUtil.convertOneToOneProperty(guideComponent, prop);
                case {'edit', 'listbox', 'popupmenu'}
                    % UIControl in Java had special logic for listbox,
                    % edit, and popupmenu - if these three had their
                    % background set to the factory value, then the view
                    % would display a white background color instead of the
                    % factory value.
                    factoryBackgroundColor = get(groot, 'factoryUIControlBackgroundColor');
                    newBackgroundColor = guideComponent.(prop);

                    if isequal(factoryBackgroundColor, newBackgroundColor)
                        pvp = {'BackgroundColor', [1 1 1]};
                    else
                        pvp = BasePropertyConversionUtil.convertOneToOneProperty(guideComponent, prop);
                    end
                otherwise
                    % Do nothing, not applicable for the other styles
            end
        end

        function pvp = convertEnable(guideComponent, prop)
            import matlab.ui.internal.componentconversion.BasePropertyConversionUtil;

            switch guideComponent.Style
                case 'frame'
                    % Frames do not have any visual difference when their
                    % enable value is changed.
                    pvp = [];
                otherwise
                    pvp = BasePropertyConversionUtil.convertEnable(guideComponent, prop);
            end
        end

        function pvp = convertUnits(guideComponent, ~)
            % For Units property that comes in, we need to update Position
            % on the backing UIComponent.

            pos = guideComponent.Position;
            units = guideComponent.Units;

            switch guideComponent.Style
                case 'frame'
                    % Characters are boarded up in general, and inches,
                    % points, and centimeters are boarded up on Mac.
                    % Thus we need to assign either Pixels or Normalized
                    % as the units for the backing panel.
                    if any(strcmp(units, {'points', 'inches', 'centimeters', 'characters'}))
                        units = 'pixels';
                        pos = getpixelposition(guideComponent);
                    end
                otherwise
                    % no-op, translate position / units as is
            end

            % Used for uicontrol normalized.
            pvp = {'Units', units, 'Position', pos};
        end

        function pvp = convertFontUnits(guideComponent, ~)
            % Common across: uicontrol, uibuttongroup, uipanel, uitable

            % When Font Units is changed, we need to push the FontSize
            % through to the peernode with the value in its native units.
            % Therefore, convertFontUnits generates a PV pair for FontSize.
            fontSize = guideComponent.FontSize;
            fontUnits = guideComponent.FontUnits;

            pvp = {'FontUnits', fontUnits, 'FontSize', fontSize};
        end

        function pvp = convertForegroundColor(guideComponent, prop)

            import matlab.ui.internal.componentconversion.BasePropertyConversionUtil;

            switch guideComponent.Style
                case 'frame'
                    pvp = {'HighlightColor', guideComponent.(prop)};

                otherwise
                    pvp = BasePropertyConversionUtil.convertOneToOneProperty(...
                        guideComponent, prop);

                    if ~isempty(pvp)
                        % Replace 'ForegroundColor' to 'FontColor' as that is the
                        % new API.
                        pvp{1} = 'FontColor';
                    end
            end
        end

        function pvp = convertCData(guideComponent, ~)

            pvp = [];

            cdata = guideComponent.CData;

            switch guideComponent.Style
                case {'pushbutton', 'togglebutton'}
                    % For pushbuttons and togglebuttons, set the CData
                    % directly on the buttons.  The Icon property now
                    % supports CData.
                    pvp = {'Icon', cdata, 'IconAlignment', 'center'};
                case {'checkbox', 'radiobutton'}
                    % GUIDE users would uses the cdata property on for
                    % these components to display 2D images. This is
                    % now supported for the UIControl Redirect via the
                    % Image component.
                    %
                    % UIControls would render NaN as transparent
                    % pixels.  This is now supported by the ImageSource
                    % property of UIImage as well.

                    % Left-align the image to mimic the appearance of
                    % the Java UIControls - they render the image
                    % left-aligned horizontally and center-aligned
                    % vertically.
                    pvp = {'ImageSource', cdata, 'ScaleMethod', 'none', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'center'};
                otherwise
                    % Do nothing, not applicable for the other styles
            end
        end

        function pvp = convertHorizontalAlignment(guideComponent, prop)

            pvp = [];
            horizontalAlignment = guideComponent.(prop);

            switch guideComponent.Style
                case {'edit', 'text'}
                    pvp = {'HorizontalAlignment', horizontalAlignment};
                otherwise
                    % Do nothing, not applicable for the other styles
            end
        end

        function pvp = convertListboxTop(guideComponent, ~)
            pvp = [];

            switch guideComponent.Style
                case 'listbox'
                    % ListboxTop has been removed. However, a potential
                    % workaround is to use the new uilistbox scroll method
                    % in the app's startupFcn. Only report the issue if the
                    % ListboxTop is not 1 (scrolled to top).
                otherwise
                    % Do nothing, not applicable for the other styles
            end
        end

        function pvp = convertMaxAndMin(guideComponent, ~)

            pvp = [];
            max = guideComponent.Max;
            min = guideComponent.Min;

            switch guideComponent.Style
                case 'listbox'
                    % Max and Min are used to determine if the listbox
                    % allows multi-selection or not. If the difference
                    % between max and min is greater than one, then it is
                    % multi-select.
                    if (max - min) > 1
                        multiselect = 'on';
                    else
                        multiselect = 'off';
                    end
                    pvp = {'Multiselect', multiselect};
                case 'slider'
                    pvp = {'Limits', [min, max]};
                otherwise
                    % Do nothing, not applicable for the other styles
            end
        end

        function pvp = convertPosition(guideComponent, prop)
            pos = guideComponent.(prop);

            switch guideComponent.Style
                case 'slider'
                    pixPos = getpixelposition(guideComponent);
                    % If height, is greater than width, the orientation
                    % of the slider should be verticial.
                    if pixPos(4) > pixPos(3)
                        orientation = 'vertical';
                    else
                        orientation = 'horizontal';
                    end
                    pvp = {'Orientation', orientation, 'Position', pos};

                otherwise
                    pvp = {'Position', pos};
            end
        end

        function pvp = convertSliderStep(guideComponent, prop)
            import matlab.ui.internal.componentconversion.BasePropertyConversionUtil;
            pvp = [];
            step = guideComponent.(prop);

            switch guideComponent.Style
                case 'slider'
                    pvp = {'Step', step};
                otherwise
                    % Do nothing, not applicable for the other styles
            end
        end

        function pvp = convertString(guideComponent, prop)

            import matlab.ui.internal.componentconversion.BasePropertyConversionUtil;

            pvp = [];
            str = guideComponent.(prop);

            % Convert padded character matrix to cell array
            if BasePropertyConversionUtil.isPaddedCharacterMatrix(str)
                str = cellstr(str);
            end

            % Normalize empty values of different types and sizes to be the
            % same. Otherwise, strip newline and carriage returns.
            if isempty(str)
                str = '';
            else
                str = BasePropertyConversionUtil.stripNewlineAndCarriageReturns(str);
            end

            switch guideComponent.Style
                case 'edit'
                    % App Designer editfields don't support cell arrays and
                    % so only take first element if it is a cell. However,
                    % if Max - min > 1 then the component will be migrated
                    % as a textarea which does support cell arrays.
                    if iscell(str) && ~(guideComponent.Max - guideComponent.Min > 1)
                        str = str{1};
                    end

                    pvp = {'Value', str};
                case {'listbox', 'popupmenu'}
                    if isempty(str)
                        str = {};
                    end

                    % App Designer listbox and dropdown menus only accept
                    % cell array inputs and so need to convert to cell.
                    if ischar(str)
                        str = {str};
                    end

                    % Setting the value here instead of convertValue
                    % because the value is dependant on what is set for
                    % the GUIDE String property. In GUIDE, the value is the
                    % numeric index of the items. In App Designer, the
                    % value is the actual string of the list item
                    value = guideComponent.Value;
                    if ~isempty(str) && ~isempty(value)
                        if isscalar(value)
                            value = str{value};
                        else
                            % g1975105: Strip out duplicate indices, as the uilistbox API
                            % does not allow for setting value = {'a' 'a'} if there is
                            % only one 'a' in the items.
                            value = unique(value);
                            value = str(value);
                        end
                    else
                        value = {};
                    end

                    pvp = {'Items', str, 'Value', value};
                case 'slider'
                    % Do nothing, not applicable
                case {'checkbox', 'pushbutton', 'radiobutton', 'text', 'togglebutton'}
                    pvp = {'Text', str};
            end
        end

        function pvp = convertValue(guideComponent, prop)

            pvp = [];
            value = guideComponent.(prop);

            switch guideComponent.Style
                case {'checkbox', 'radiobutton', 'togglebutton'}
                    % Value when comparecd with Max, indicates if the
                    % component is selected. When value == max, the
                    % component is selected. Otherwise, is not selected.
                    if value == guideComponent.Max
                        newValue = true;
                    else
                        children = findall(guideComponent.Parent, 'Style', guideComponent.Style);
                        if ~isequal(guideComponent.Style,'checkbox') ...
                                && isa(guideComponent.Parent, 'matlab.ui.control.ButtonGroup') ...
                                && isequal(children(end), guideComponent)
                            % Component is a radiobutton or togglebutton
                            % and is the first child of a button group
                            % (added first so 'end' of the children list).
                            % We can't set the selected state to false for
                            % the first child because this will throw an
                            % error. So we will set it to true. It is
                            % likely that there are other buttons and when
                            % one of them is set to true this button will
                            % get changed to false.
                            newValue = true;
                        else
                            newValue = false;
                        end
                    end
                    pvp = {'Value', newValue};
                case {'listbox', 'popupmenu'}
                    % Call the ConvertString code, which handles both String & Value.
                    % In migration tool usages, this is not needed - we could do nothing. However, in the runtime
                    % case of the uicontrol redirect, it is necessary to do something if the user sets just the value,
                    % so set the value through this code.  A harmless side effect is that the Items on the uicomponent
                    % will be set an extra time.
                    pvp = matlab.ui.internal.componentconversion.UicontrolConversionUtils.convertString(guideComponent, 'String');
                case {'slider'}
                    pvp = {'Value', value};
                otherwise
                    % Do nothing, not applicable for the other styles
            end
        end
    end
end
