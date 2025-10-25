function [omitnan,flag,allFlag,linearFlag] = validateMissingOptionAllFlag(option,includeAll,includeLinear) %#codegen
%VALIDATEMISSINGOPTIONALLFLAG Validate the NaN-flag or the 'all' or 'linear' flag for datetime methods.
%   [OMITNAN,FLAG,ALLFLAG,LINEARFLAG] = VALIDATEMISSINGOPTIONALLFLAG(OPTION,INCLUDEALL)
%   returns OMITNAN as true if either 'omitmissing', 'omitnan', or 'omitnat' was
%   specified or if OPTION is not a NaN-flag (i.e. 'all' or 'linear', since the
%   NaN-flag is 'omitnan' by default). FLAG is the input option mapped to
%   the core MATLAB equivalent if necessary (e.g. 'includemissing' becomes
%   'includenan'). If OPTION is 'all' or 'linear', then FLAG is 'omitnan'.
%   ALLFLAG is true if OPTION is 'all' and LINEARFLAG is true if OPTION is
%   'linear'. INCLUDEALL, which is false by default, determines whether
%   'all' should be included in the error message.
%
%   See also validateMissingOption.

%   Copyright 2020-2023 The MathWorks, Inc.

if nargin < 2
    % includeAll determines if 'all' should be included in the error
    % message or not
    includeAll = false;
end
if nargin < 3
    % includeLinear determines if 'linear' should be included in the error
    % messages or not
    includeLinear = false;
end

coder.internal.errorIf(~matlab.internal.coder.datatypes.isScalarText(option,false) && includeAll && ~includeLinear,'MATLAB:datetime:UnknownNaNFlagAllFlag');
coder.internal.errorIf(~matlab.internal.coder.datatypes.isScalarText(option,false) && includeAll && includeLinear,'MATLAB:datetime:UnknownNaNFlagAllLinearFlag');
coder.internal.errorIf(~matlab.internal.coder.datatypes.isScalarText(option,false) && ~includeAll,'MATLAB:datetime:UnknownNaNFlag');

s = strncmpi(option, {'omitmissing' 'omitnan' 'omitnat' 'includemissing' 'includenan' 'includenat' 'all' 'linear'}, strlength(option));

linearFlag = false;

if s(1) || s(2) || s(3)
    omitnan = true;
    flag = 'omitnan';
    allFlag = false;
elseif s(4) || s(5) || s(6)
    omitnan = false;
    flag = 'includenan';
    allFlag = false;
elseif s(7)
    omitnan = true; % Set to the default value
    flag = 'omitnan';
    allFlag = true;
elseif s(8)
    coder.internal.errorIf(~includeLinear,'MATLAB:min:linearNotSupported');
    
    omitnan = true;
    flag = 'omitnan';
    linearFlag = true;
    allFlag = false;
else
    
    coder.internal.errorIf(includeAll && ~includeLinear,'MATLAB:datetime:UnknownNaNFlagAllFlag');
    coder.internal.errorIf(includeAll && includeLinear,'MATLAB:datetime:UnknownNaNFlagAllLinearFlag');
    coder.internal.errorIf(~includeAll,'MATLAB:datetime:UnknownNaNFlag');
end

