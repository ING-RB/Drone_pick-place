classdef (Hidden) UIComponentConversionUtils < ...
        matlab.ui.internal.componentconversion.BasePropertyConversionUtil
    %UICOMPONENTCONVERSIONTUTILS Utility class to help translate properties
    % from UI components (e.g. uibutton, uilabel) to their equivalents for
    % UIControls, as part of the UIControlPropertiesConverter

    % Copyright 2019-2022 The Mathworks, Inc.

    properties (Constant)
        PropertyConversionFunctionPairs = matlab.ui.internal.componentconversion.UIComponentConversionUtils.buildPropertyConversionFunctionPairs();
    end

    methods (Static)

        function conversionFuncs = getPropertyConversionFunctions()
            conversionFuncs = matlab.ui.internal.componentconversion.UIComponentConversionUtils.PropertyConversionFunctionPairs;
        end

        function conversionFuncPairs = buildPropertyConversionFunctionPairs()
            import matlab.ui.internal.componentconversion.UIComponentConversionUtils;
            import matlab.ui.internal.componentconversion.BasePropertyConversionUtil;

            conversionFuncPairs = {...
                {'BackgroundColor'    , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'BusyAction'         , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'ButtonPushedFcn'    , @UIComponentConversionUtils.convertCallback},...
                {'CreateFcn'          , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'DeleteFcn'          , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'Editable'           , @BasePropertyConversionUtil.noopConversionFunction},...
                {'Enable'             , @UIComponentConversionUtils.convertEnable},...
                {'FontAngle'          , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'FontColor'          , @UIComponentConversionUtils.convertFontColor},...
                {'FontName'           , @UIComponentConversionUtils.convertFontName},...
                {'FontSize'           , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'FontWeight'         , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'HandleVisibility'   , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'HorizontalAlignment', @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'Icon'               , @UIComponentConversionUtils.convertIcon},...
                {'IconAlignment'      , @UIComponentConversionUtils.convertIconAlignment},...
                {'InnerPosition'      , @BasePropertyConversionUtil.noopConversionFunction},...
                {'Interruptible'      , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'Items'              , @UIComponentConversionUtils.convertItems},...
                {'ItemsData'          , @BasePropertyConversionUtil.noopConversionFunction},...
                {'Layout'             , @BasePropertyConversionUtil.noopConversionFunction},...
                {'Limits'             , @UIComponentConversionUtils.convertLimits},...
                {'MajorTickLabels'    , @BasePropertyConversionUtil.noopConversionFunction},...
                {'MajorTickLabelsMode', @BasePropertyConversionUtil.noopConversionFunction},...
                {'MajorTicks'         , @BasePropertyConversionUtil.noopConversionFunction},...
                {'MajorTicksMode'     , @BasePropertyConversionUtil.noopConversionFunction},...
                {'MinorTicks'         , @BasePropertyConversionUtil.noopConversionFunction},...
                {'MinorTicksMode'     , @BasePropertyConversionUtil.noopConversionFunction},...
                {'Multiselect'        , @UIComponentConversionUtils.convertMultiselect},...
                {'Orientation'        , @BasePropertyConversionUtil.noopConversionFunction},...
                {'OuterPosition'      , @BasePropertyConversionUtil.noopConversionFunction},...
                {'Parent'             , @BasePropertyConversionUtil.noopConversionFunction},...
                {'Position'           , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'Tag'                , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'Text'               , @UIComponentConversionUtils.convertText},...
                {'Tooltip'            , @UIComponentConversionUtils.convertTooltip},...
                {'UserData'           , @BasePropertyConversionUtil.convertUserData},...
                {'Units'              , @BasePropertyConversionUtil.convertOneToOneProperty},...
                {'Value'              , @UIComponentConversionUtils.convertValue}...
                {'ValueChangedFcn'    , @UIComponentConversionUtils.convertCallback},...
                {'VerticalAlignment'  , @BasePropertyConversionUtil.noopConversionFunction},...
                {'Visible'            , @BasePropertyConversionUtil.convertOneToOneProperty},...
                };

        end

        function pvp = convertText(uicomponent, prop)
            text = uicomponent.(prop);

            pvp = {'String', text};
        end

        function pvp = convertEnable(uicomponent, prop)
            componentValue = uicomponent.(prop);
            if isa(componentValue, 'matlab.lang.OnOffSwitchState')
                if componentValue
                    value = 'on';
                else
                    value = 'off';
                end
            else
                value = componentValue;
            end

            pvp = {'Enable', value};
        end

        function pvp = convertFontName(uicomponent, prop)
            import matlab.ui.internal.componentconversion.BasePropertyConversionUtil;

            fontName = uicomponent.(prop);
            fontName = BasePropertyConversionUtil.stripNewlineAndCarriageReturns(fontName);

            pvp = {'FontName', fontName};
        end

        function pvp = convertFontColor(uicomponent, prop)
            fc = uicomponent.(prop);

            pvp = {'ForegroundColor', fc};
        end

        function pvp = convertTooltip(uicomponent, prop)
            tooltip = uicomponent.(prop);

            if iscellstr(tooltip) || isstring(tooltip)
                tooltip = join(tooltip, newline);
                if iscell(tooltip)
                    tooltip = tooltip{1};
                end
            end

            pvp = {'TooltipString', tooltip};
        end

        function pvp = convertIcon(uicomponent, prop) %#ok<INUSD> 
            % do we do anything here?
            pvp = [];
        end

        function pvp = convertIconAlignment(uicomponent, prop) %#ok<INUSD> 
            % again, anything?
            pvp = [];
        end

        function pvp = convertItems(uicomponent, prop)
            items = uicomponent.(prop);

            pvp = {'String', items};
        end

        function pvp = convertLimits(uicomponent, prop)
            limits = uicomponent.(prop);

            pvp = {'Min', limits(1), 'Max', limits(2)};
        end

        function pvp = convertMultiselect(uicomponent, prop)
            ms = uicomponent.(prop);
            if strcmp(ms, 'on')
                pvp = {'Min', 0, 'Max', 2};
            else
                pvp = {'Min', 0, 'Max', 1};
            end
        end

        function pvp = convertValue(uicomponent, prop)
            switch uicomponent.Type
                case {'uistatebutton', 'uicheckbox', 'uiradiobutton', 'uislider', }
                    val = uicomponent.(prop);
                    pvp = {'Value', val};
                case 'uidropdown'
                    val = uicomponent.(prop);

                    if isempty(uicomponent.ItemsData)
                        valIndex = find(strcmp(val, uicomponent.Items));
                    else
                        if ischar(uicomponent.ItemsData) || iscellstr(uicomponent.ItemsData)
                            data = convertCharsToStrings(uicomponent.ItemsData);
                        else
                            data = uicomponent.ItemsData;
                        end

                        valIndex = find(val == data);
                    end
                    pvp = {'Value', valIndex};
                case 'uilistbox'
                    % Per the doc, if ItemsData exists, the Value property
                    % must be an element or elements of ItemsData.  If
                    % ItemsData doesn't exist, Value must be an element of
                    % Items.  Added as part of g2510117.
                    if isempty(uicomponent.ItemsData)
                        data = uicomponent.Items;
                    else
                        data = uicomponent.ItemsData;
                    end

                    % Determines the indices of each element of 'val' in
                    % the 'data' cellstr.
                    val = uicomponent.(prop);
                    [~, valueArray] = ismember(val, data);
                    valueArray = sort(valueArray);

                    pvp = {'Value', valueArray};
                case {'uieditfield', 'uitextarea'}
                    val = uicomponent.(prop);
                    pvp = {'String', val};
                otherwise % Button, label
                    pvp = [];
            end
        end

        function pvp = convertCallback(uicomponent, prop)
            cb = uicomponent.(prop);

            pvp = {'Callback', cb};
        end
    end
end