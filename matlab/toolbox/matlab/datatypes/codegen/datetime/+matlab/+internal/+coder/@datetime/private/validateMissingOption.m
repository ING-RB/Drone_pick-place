function [omitnan,flag] = validateMissingOption(option,includeLinear) %#codegen
%VALIDATEMISSINGOPTION Validate the NaN-flag argument for datetime methods.
%   [OMITNAN,FLAG] = VALIDATEMISSINGOPTION(OPTION) returns OMITNAN as true
%   if OPTION is either 'omitmissing', 'omitnan', or 'omitnat'. FLAG is the
%   input option mapped to the core MATLAB equivalent if necessary (e.g.
%   'includemissing' becomes 'includenan').
%
%   See also validateMissingOptionAllFlag.

%   Copyright 2020-2023 The MathWorks, Inc.

if nargin < 2
    % includeLinear determines if 'linear' should be included in the error
    % messages or not
    includeLinear = false;
end

% weed out '', "", or <missing>
coder.internal.errorIf(~matlab.internal.coder.datatypes.isScalarText(option,false) && ~includeLinear,'MATLAB:datetime:UnknownNaNFlag');
coder.internal.errorIf(~matlab.internal.coder.datatypes.isScalarText(option,false) && includeLinear,'MATLAB:datetime:UnknownNaNFlagAllLinearFlag');

possibleFlags    = {'omitmissing' 'omitnan', 'omitnat', 'includemissing' 'includenan' ,'includenat'};
possibleOmitNans = [ 1,            1,         1,         2,               2,            2          ]; 
if includeLinear
    choiceNum = matlab.internal.coder.datatypes.getChoice(option,possibleFlags,possibleOmitNans,'MATLAB:datetime:UnknownNaNFlagAllLinearFlag');
else
    choiceNum = matlab.internal.coder.datatypes.getChoice(option,possibleFlags,possibleOmitNans,'MATLAB:datetime:UnknownNaNFlag');
end

if choiceNum == 1
    omitnan = true;
else
    omitnan = false;
end
    
    
if omitnan
    flag = 'omitnan';
else
    flag = 'includenan';
end

