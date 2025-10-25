% Return the summary for types which may have a classUnderlying type

% Copyright 2015-2024 The MathWorks, Inc.

function renderedData = getClassUnderlyingTypeSummary(currentVal)
    import internal.matlab.datatoolsservices.FormatDataUtils;

    cls = class(currentVal);
    secondaryType = [];
    if any(strcmp(cls, ["distributed", "codistributed", "gpuArray"]))
        try
            secondaryType = underlyingType(currentVal);
        catch
            % This can error in cases, such as when the distributed pool is
            % shutdown. It can just be ignored, as the variable will be
            % displayed as <Error displaying value>, because any access of it
            % will fail (size, class, etc)
            internal.matlab.datatoolsservices.logDebug("datatoolsservices::formatdatautils", "Error accessing classUnderlying for variable");
        end
    elseif ismethod(currentVal, 'classUnderlying')
        try
            secondaryType = classUnderlying(currentVal);
        catch
            % This can error in cases, such as when the distributed pool is
            % shutdown. Show a message that the value is invalid (similar to the
            % command line)
            renderedData = getString(...
                message('MATLAB:codetools:variableeditor:InvalidDistributedValue', ...
                class(currentVal)));
            return;
        end
    end

    renderedData = FormatDataUtils.getValueSummaryString(...
        currentVal, secondaryType);
end
