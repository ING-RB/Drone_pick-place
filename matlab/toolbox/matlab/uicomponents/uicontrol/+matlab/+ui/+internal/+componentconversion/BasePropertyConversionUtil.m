classdef (Abstract) BasePropertyConversionUtil
    %BASEPROPERTYCONVERSIONUTIL Common property conversion functions
    %   Utility of common property conversion functions that are shared
    %   amongst the various ComponentConverters in the GUIDE to App Designer migration
    %   tool and the uicontrol redirect.  When updating this file any impact on these
    %   tools must be taken into account.

    %   Copyright 2019-2022 The MathWorks, Inc.

    methods (Static)
        function pvp = noopConversionFunction(~, ~)
            pvp = {};
        end

        function pvp = convertOneToOneProperty(guideComponent, prop)
            pvp = {prop, guideComponent.(prop)};
        end

        function str = stripNewlineAndCarriageReturns(str)
            % Replace any carriage returns & newline with empty string
            % Code gen breaks if carriage returns or newline exist

            % Newline = char(10)
            str = strrep(str,newline,'');

            % Carriage return
            str = strrep(str, char(13), '');

        end

        function isPadded = isPaddedCharacterMatrix(str)
            % Returns true if the input string is a padded character matrix
            % (e.g. str = ['abc';'def';'hij'])

            isPadded = false;
            if ischar(str) && ~isempty(str) && ~isrow(str)
                isPadded = true;
            end
        end

        function pvp = convertPosition(guideComponent, prop)

            pos = guideComponent.(prop);

            % Round the position so that we don't have extra floating point
            % cruft
            pos = round(pos);

            pvp = {'Position', pos};
        end

        function pvp = convertEnable(guideComponent, prop)
            % Common across: uicontrol, uitable, uimenu

            enable = guideComponent.(prop);

            % The value 'inactive' is no longer supported. Convert this to
            % 'off' and don't create an issue as this is a minor cosmetic
            % difference.
            if strcmpi(enable, 'inactive')
                enable = 'off';
            end

            pvp = {'Enable', enable};
        end

        function pvp = convertFontAngle(guideComponent, prop)
            % Common across: uicontrol, uibuttongroup, uipanel, uitable

            fontAngle = guideComponent.(prop);

            % The value 'oblique' is no longer supported. Convert this to
            % 'italic' and don't create an issue as this is a minor
            % cosmetic difference.
            if strcmpi(fontAngle, 'oblique')
                fontAngle = 'italic';
            end

            pvp = {'FontAngle', fontAngle};
        end

        function pvp = convertFontName(guideComponent, prop)

            import matlab.ui.internal.componentconversion.BasePropertyConversionUtil;

            pvp = BasePropertyConversionUtil.convertOneToOneProperty(...
                guideComponent, prop);

            % replace any carriage returns/newline characters present in font
            % for example, font can be set as:
            % comp.FontName = ['Arial' newline 'Black'];
            % here newline creates a newline character which needs to be
            % stripped
            if(~isempty(pvp))
                pvp{2} = BasePropertyConversionUtil.stripNewlineAndCarriageReturns(pvp{2});
            end
        end

        function pvp = convertFontSize(guideComponent, prop)
            % Common across: uicontrol, uibuttongroup, uipanel, uitable

            % guideComponent.FontUnits should have been set to 'pixels'
            % before this conversion. Round the FontSize to the nearest
            % integer value.
            fontSize = guideComponent.(prop);

            pvp = {'FontSize', fontSize};
        end

        function pvp = convertFontWeight(guideComponent, prop)
            % Common across: uicontrol, uibuttongroup, uipanel, uitable

            fontWeight = guideComponent.(prop);

            % The values 'light' and 'demi' are no longer supported.
            % Convert them to 'normal' and don't create an issue as this is
            % a minor cosmetic difference.
            if strcmpi(fontWeight, 'light') || strcmpi(fontWeight, 'demi')
                fontWeight = 'normal';
            end

            pvp = {'FontWeight', fontWeight};
        end

        function pvp = convertUserData(guideComponent, prop)
            pvp = [];
        end

        function pvp = convertTooltipString(guideComponent, prop)
            % Common across all components
            tooltip = guideComponent.(prop);
            % TooltipString has been renamed to Tooltip
            % and is now available on all relevant App Designer components
            pvp = {'Tooltip',tooltip};
        end
    end

    methods (Static)

        % These functions duplicate logic in the GUIDE -> App Designer migration tool.
        % TODO g1976072: remove this duplication.
        function pvp = convertProperties(guideComponent, propConversionFunctions)
            pvp = [];

            % Loop over each property and perform the conversion
            for i=1:length(propConversionFunctions)
                conversionInfo = propConversionFunctions{i};
                propToConvert = conversionInfo{1};
                conversionFunction = conversionInfo{2};

                try
                    compPvp = conversionFunction(guideComponent, propToConvert);
                catch ME %#ok<NASGU>
                    compPvp = [];
                end

                pvp = [pvp compPvp]; %#ok<AGROW>
            end
        end

        function applyPropertyValuePairs(newComponent, pvp)
            % Use direct property set rather than graphics "set" function.
            % The graphics "set" function is built for flexibility, not performance.
            for idx=1:2:length(pvp)
                try 
                    newComponent.(pvp{idx}) = pvp{idx+1};
                catch MEignored %#ok<NASGU>
                end
            end
        end

        function [oldUnits, oldFontUnits] = forceUnitsToPixels(guideComponent)
            if isprop(guideComponent, 'Units')
                oldUnits = guideComponent.Units;
                guideComponent.Units = 'pixels';
            end

            if isprop(guideComponent, 'FontUnits')
                oldFontUnits = guideComponent.FontUnits;
                guideComponent.FontUnits = 'pixels';
            end
        end

        function resetUnits(guideComponent, oldUnits, oldFontUnits)
            if isprop(guideComponent, 'Units')
                guideComponent.Units = oldUnits;
            end

            if isprop(guideComponent, 'FontUnits')
                guideComponent.FontUnits = oldFontUnits;
            end
        end
    end
end

