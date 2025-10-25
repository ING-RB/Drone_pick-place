function extent = calculateExtent(obj)
    import matlab.ui.internal.componentconversion.BasePropertyConversionUtil;

    % Define an offset that will be added to the computed Extent value.
    % This helps add some padding around the text for components with some
    % outer art (e.g. Button).
    OFFSET = [4 6];

    fontName = obj.FontName;

    % Use the BasePropertyConversionUtil to compute the FontAngle and
    % FontWeight values that will actually be applied to the component, as
    % some deprecated values are still accepted by the UIControl.
    % These calls will convert the deprecated values to valid ones.
    fontAnglePVPairs = BasePropertyConversionUtil.convertFontAngle(obj, 'FontAngle');
    fontAngle = fontAnglePVPairs{2};
    fontWeightPVPairs = BasePropertyConversionUtil.convertFontWeight(obj, 'FontWeight');
    fontWeight = fontWeightPVPairs{2};

    oldFontUnits = obj.FontUnits;
    % PF layer requires Points for the font size
    obj.FontUnits = 'points';
    cleanup = onCleanup(@() set(obj, 'FontUnits', oldFontUnits));
    fontSize = obj.FontSize;
    text = obj.String;

    if isempty(text)
        text = '';
    end

    if BasePropertyConversionUtil.isPaddedCharacterMatrix(text)
        text = cellstr(text);
    end

    % Empty lines will be reduced
    % Use a placeholder to ensure height is still accounted for
    if iscell(text)
        emptyElements = find(cellfun(@isempty,text));
        if ~isempty(emptyElements) 
            [text{emptyElements}] = deal('.');
        end
    end

    % Controls with style 'text' are always considered multiline.
    isMultiline = strcmp(obj.Style, 'text') || obj.Max - obj.Min > 1;

    % When Max - Min <= 1 for UIControls, the Extent only matches the width
    % and height of the first element in the String.
    % When Max - Min > 1, the Extent takes all elements in String into
    % account.
    if ~isMultiline && iscell(text)
        text = text{1};
    end

    screenDPI = get(groot, 'ScreenPixelsPerInch');
    
    extent = matlab.graphics.internal.getTextExtents(text, fontName, fontSize, fontAngle, fontWeight, screenDPI);
    % Add the offset to pad the component
    extent = extent + OFFSET;
    % PF layer returns points for the extent value
    extent = [0 0 extent(1:2)];
end