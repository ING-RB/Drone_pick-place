classdef UIControlConversionRules < handle
% UICONTROLCONVERSIONRULES Static set of conversion rules from a uicontrol
% model to webview.

%   Copyright 2023 The MathWorks, Inc.

    methods(Static)
        % Mapping for all uicontrol
        function val = convertFontAngle(val)
            if strcmpi(val, 'oblique')
                val = 'italic';
            end
        end

        function newFontName = convertFontName(oldFontName)
            newFontName = oldFontName;
            newFontName = strrep(newFontName,newline,' ');
            newFontName = strrep(newFontName, char(13), ' ');
            newFontName = matlab.ui.internal.FontUtils.getFontForView(newFontName);
        end

        % Mapping for Slider
        function val = convertMinMaxToLimits(min, max)
            val = [min, max];
        end

        % Mapping for Listbox
        function val = convertMinMaxToMultiSelect(min, max)
            val = false;
            if (max - min > 1)
                val = true;
            end
        end

        % Mapping for Edit
        function val = convertMinMaxToMultiline(min, max)
            val = false;
            if (max - min > 1)
                val = true;
            end
        end

        % Mapping for Checkbox, RadioButton, ToggleButton
        % No need to worry about first child issues in buttongroup.
        % This is managed by the buttongroup itself.
        function newValue = convertMinMaxToValue(value, maxVal)
            if (value == maxVal)
                newValue = true;
            else
                newValue = false;
            end
        end

        % Mapping for CheckBox, RadioButton, PushButton, and ToggleButton
        function val = convertStringToText(str)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.preprocessString;
            val = preprocessString(str);
        end

        % Mapping for Edit depends on multiline
        function str = convertStringToValue(str, minVal, maxVal)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.preprocessString;
            str = preprocessString(str);
            if iscell(str) && (maxVal - minVal <= 1)
                str = str{1};
            end
        end

        % Mapping for ListBox, PopupMenu
        function str = convertStringToItems(str)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.preprocessString;
            str = preprocessString(str);
            if isempty(str) || isequal(str,{''})
                str = {};
            end

            % App Designer listbox and dropdown menus only accept
            % cell array inputs and so need to convert to cell.
            if ischar(str)
                str = {str};
            end
        end

        function iconURL = convertCData(cdata)
            if (isempty(cdata))
                iconURL = '';
                return;
            end
            iconURL = matlab.ui.internal.IconUtils.getURLFromCData(cdata);
        end

        function val = convertValueToSelectedIndex(strVal, value)
            val = [];
            if ~isempty(strVal)
                val = value;
            end
        end
        function value = convertBackgroundColorIfDefault(value, fallBackValueIfDefault)
            factoryBackgroundColor = get(groot, 'factoryUIControlBackgroundColor');
            %If the value is the default, and a fallback is provided, use
            %the fallback.
            if isequal(factoryBackgroundColor, value) && ~isempty(fallBackValueIfDefault)
                value = fallBackValueIfDefault;
            end
        end
    end



    methods(Static, Access='private')
        function val = preprocessString(str)
            import matlab.ui.internal.componentconversion.BasePropertyConversionUtil.stripNewlineAndCarriageReturns;
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.isCharacterMatrix;
            
            % Convert padded character matrix to cell array
            if isCharacterMatrix(str)
                str = cellstr(str);
            end

            % Normalize empty values of different types and sizes to be the
            % same. Otherwise, strip newline and carriage returns.
            if isempty(str)
                str = {''};
            else
                str = stripNewlineAndCarriageReturns(str);
            end

            val = str;
        end

        function isCharMatrix = isCharacterMatrix(str)
            % Returns true if the input string is a character matrix
            % (e.g. str = ['abc';'def';'hij'])

            isCharMatrix = false;
            if ischar(str) && ~isempty(str)
                isCharMatrix = true;
            end
        end
    end
end
