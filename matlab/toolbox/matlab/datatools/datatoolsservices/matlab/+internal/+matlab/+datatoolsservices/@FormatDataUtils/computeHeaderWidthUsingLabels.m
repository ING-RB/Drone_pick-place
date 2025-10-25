% Computes the width of the header given the header label using pre-defined
% character widths. TODO: Have the client widgets make these computations.

% Copyright 2015-2023 The MathWorks, Inc.

function nameWidth = computeHeaderWidthUsingLabels(name)
    import internal.matlab.datatoolsservices.FormatDataUtils;
    headerWidth = FormatDataUtils.HEADER_CHAR_WIDTH;
    % If 75% of characters are uppercase, use the HEADER_UPPER_CHAR_WIDTH
    % instead.
    len = strlength(name);
    if sum(isstrprop(name, "upper"))/strlength(name) > FormatDataUtils.HEADER_UPPER_LEN_CUTOFF
        headerWidth = FormatDataUtils.HEADER_UPPER_CHAR_WIDTH;
    end
    nameWidth = (len * headerWidth) + FormatDataUtils.VE_HEADER_CUSTOM_ICON + ...
        FormatDataUtils.VE_HEADER_MENU + FormatDataUtils.VE_HEADER_PADDING + FormatDataUtils.VE_RESIZER;
end
