function rep = compactRepresentation(obj, displayConfiguration, width, issueWarning)
% Get the compact display representation for obj based on the display
% layout and available width.

% Copyright 2021-2023 The MathWorks, Inc.
arguments
    obj matlab.display.internal.CompactDisplayProvider
    displayConfiguration (1,1) matlab.display.DisplayConfiguration
    width (1,1) double {mustBeReal, mustBePositive}
    issueWarning (1,1) logical = true
end
import matlab.display.internal.DisplayLayout;
import matlab.display.DimensionsAndClassNameRepresentation;

methodName = "";
try
    % Call compactRepresentationForSingleLine/ Column based on the
    % DisplayLayout
    if displayConfiguration.DisplayLayout == DisplayLayout.SingleLine
        methodName = "compactRepresentationForSingleLine";
        rep = compactRepresentationForSingleLine(obj, displayConfiguration, width);
    else
        methodName = "compactRepresentationForColumn";
        rep = compactRepresentationForColumn(obj, displayConfiguration, width);
    end
    % Validate value returned from compactRepresentationForSingleLine/
    % Column
    validateRepresentationObject(rep, displayConfiguration);
catch ME
    % Turn errors being thrown from compactRepresentationForSingleLine/
    % Column into warnings and default to displaying dimensions and class
    % name in this case
    if issueWarning
        warning(message('MATLAB:display:CustomCompactDisplayError', class(obj), methodName, ME.message));
    end
    rep = DimensionsAndClassNameRepresentation(obj, displayConfiguration);
end

% Fit returned representation object into available width
rep = fitDisplayRepresentationToWidth(obj, displayConfiguration, rep, width);
end

function validateRepresentationObject(rep, displayConfig)
% Make sure that returned value returned from
% compactRepresentationForSingleLine/ Column is a
% CompactDisplayRepresentation object
import matlab.display.internal.DisplayLayout;

if displayConfig.DisplayLayout == DisplayLayout.SingleLine
    methodName = "compactRepresentationForSingleLine";
else
    methodName = "compactRepresentationForColumn";
end

if ~isa(rep, "matlab.display.CompactDisplayRepresentation")
    error(message('MATLAB:display:CompactDisplayRepresentationRequired', methodName));
end
end