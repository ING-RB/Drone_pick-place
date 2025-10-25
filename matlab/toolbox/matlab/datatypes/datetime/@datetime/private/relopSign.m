function cSign = relopSign(aData,bData)
% Return the sign of the elementwise difference of two datetimes' data

%   Copyright 2015-2021 The MathWorks, Inc.

% Actually, for finite values this just returns the difference, but comparing
% that to zero is equivalent to comparing the sign to zero.
cSign = matlab.internal.datetime.datetimeSubtract(aData,bData);

nans = isnan(cSign);
% NaNs in cData might be from NaNs in aData or bData, or from (Inf - Inf)
% or (-Inf - -Inf) (but (Inf - -Inf) and (-Inf - Inf) work out OK). The
% purpose of this function, instead of calling datetimeSubtract directly,
% is to fix up those latter cases, which should be considered equal. Not
% all contexts care about that, so some just call datetimeSubtract.
if any(nans(:))
    % Subtracting the signs of NaNs/Infs/-Infs for the cases that need to be
    % patched up gives the right sign of the difference. But only overwrite
    % cSign where necessary, i.e. where it had NaNs. It will be overwritten
    % with 0 for Inf/Inf or -Inf/-Inf, or with NaN if aData or bData had NaNs.
    if isscalar(aData)
        cSign(nans) = sign(aData) - sign(bData(nans));
    elseif isscalar(bData)
        cSign(nans) = sign(aData(nans)) - sign(bData);
    elseif isequal(size(aData),size(bData))
        cSign(nans) = sign(aData(nans)) - sign(bData(nans));
    else
        % Subtract the (datetime-unaware) signs for all elements, so that
        % implicit expansion can happen. Where cSign had NaNs, the
        % (datetime-unaware) diff is valid (elsewhere, it may not be because
        %  of sign's behavior on complex).
        cSignTmp = sign(aData) - sign(bData);
        cSign(nans) = cSignTmp(nans);
    end
end
