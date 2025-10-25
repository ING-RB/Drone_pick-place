function [b, m] = std(a,wgtFlag,dim,missingFlag)
%

%   Copyright 2015-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.isValidDimArg

haveDim = false;
if nargin < 4
    missingFlag = "includemissing";
    omitMissing = false;
end
if nargin == 1 % std(a)
    wgtFlag = 0;
else
    % Recognize WGTFLAG, and then DIM, if present as the 2nd and 3rd inputs, and
    % recognize a trailing string option if present. The core std function will do
    % more complete validation on WGTFLAG and DIM.
    if isnumeric(wgtFlag)
        if nargin == 2 % std(a,wgt)
            % OK
        else
            haveDim = isValidDimArg(dim); % positive scalar or 'all'
            if haveDim
                % no need to reshape to col for 'all', datetimeSubtract below implicit expands
                if nargin == 3 % std(a,wgt,dim)
                    % OK
                else % std(a,wgt,dim,missing)
                    errID = "MATLAB:datetime:UnknownNaNFlag"; % dim already found, don't suggest 'all'
                    [omitMissing,missingFlag] = validateDatafunOptions(missingFlag,errID);
                end
            elseif (nargin == 3) && isScalarText(dim) % might be std(a,wgt,missing)
                missingFlag = dim; % shift input arg
                errID = "MATLAB:datetime:UnknownNaNFlagAllFlag";
                [omitMissing,missingFlag] = validateDatafunOptions(missingFlag,errID);
            else
                error(message('MATLAB:datetime:InvalidVecDim'));
            end
        end
    elseif isScalarText(wgtFlag) && (nargin == 2) % std(a,missing)
        missingFlag = wgtFlag; % shift input arg
        errID = "MATLAB:datetime:UnknownNaNFlag"; % mimic core std: throw UnknownNaNFlag instead of UnknownNaNFlagAllFlag
        [omitMissing,missingFlag] = validateDatafunOptions(missingFlag,errID);
        wgtFlag = 0;
    else
        % Let the core std throw the error for WGTFLAG
        if ~isa(a,"datetime")
            [b,m] = matlab.internal.datatypes.fevalFunctionOnPath("std",a,wgtFlag);
            return;
        end
    end
end

% Compute (duration) differences from the (datetime) mean. This preserves
% maximal precision in the conversion to double. Switch on omitMissing to
% minimize input processing in datetime/mean.
if omitMissing
    if haveDim
        m = mean(a,dim,missingFlag);
    else
        m = mean(a,missingFlag); % different empty behavior when dim not provided
    end
else
    if haveDim
        m = mean(a,dim);
    else
        m = mean(a); % different empty behavior when dim not provided
    end
end
dm = matlab.internal.datetime.datetimeSubtract(a.data,m.data); % implicit expands m.data, returns double

% Call the core std function to leverage its input checking on WGTFLAG, but
% switch on omitMissing to minimize input processing.
if omitMissing
    if haveDim
        [b, mdur] = std(dm,wgtFlag,dim,missingFlag);
    else
        [b, mdur] = std(dm,wgtFlag,missingFlag); % different empty behavior when dim not provided
    end
else
    if haveDim
        [b, mdur] = std(dm,wgtFlag,dim);
    else
        [b, mdur] = std(dm,wgtFlag); % different empty behavior when dim not provided
    end
end
b = duration.fromMillis(b);
if mdur ~= 0
    % If weights are provided, mean of the durations may be non-zero, so add it
    % back to the original mean of the datetimes. 
    % mdur is a double representing millis.
    m.data = matlab.internal.datetime.datetimeAdd(m.data,mdur);
end
