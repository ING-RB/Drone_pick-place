% Returns the compact display for data

 % Copyright 2015-2024 The MathWorks, Inc.
 % Get CompactDisplay represetation for given currentVal. 
 % Create a DisplayConfiguration object to communicate environment
 % information
function [renderedData, isDimsAndClassName] = getCompactDisplayForData(currentVal, displayConfig)
    arguments
        currentVal
        displayConfig = matlab.display.DisplayConfiguration;
    end

   % If displayConfig is columnar, do not display DataDelimiters [] within
   % the cell.
    if isequal(displayConfig.DisplayLayout, "Columnar")
        displayConfig.DataDelimiters = "";
    else
        % For scalars, we do not want to show delimiters like []
        % irrespective of the container type.
        displayConfig.OmitDataDelimitersForScalars = true;
    end
    isDimsAndClassName = false;

    % Get the compact display for the object being displayed. 
    % Third input parameter is the available space to display the object which can be
    % set to the max string width in the live editor
    % Fourth input parameter is setting issueWarnings to false, this will
    % prevent API from erroring and return DimensionsAndClassNameRepresentation 
    % The API automatically fits representation to the given width provided.
    rep = compactRepresentation(currentVal, displayConfig, 10000, false);
    renderedData  = rep.PaddedDisplayOutput;

    if isa(rep, "matlab.display.DimensionsAndClassNameRepresentation")
        % A summary representation was returned
        isDimsAndClassName = true;
        if ~strcmp(displayConfig.DataDelimiters, "")
            displayConfig.DataDelimiters = "";
            rep = compactRepresentation(currentVal, displayConfig, 10000, false);
            renderedData  = rep.PaddedDisplayOutput;
        end
        renderedData = internal.matlab.datatoolsservices.FormatDataUtils.correctDimensionSpec(renderedData);
    end
end
