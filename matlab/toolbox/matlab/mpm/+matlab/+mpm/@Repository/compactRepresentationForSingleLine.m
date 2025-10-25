function rep = compactRepresentationForSingleLine(obj,displayConfiguration,width)

    rep = compactRepresentationForSingleLine@matlab.mixin.CustomCompactDisplayProvider(...
            obj, displayConfiguration, width);
    if ~isscalar(obj)
        return
    end
    useName = displayString(obj);
    rep = widthConstrainedDataRepresentation(obj, displayConfiguration, width, StringArray=useName);
end