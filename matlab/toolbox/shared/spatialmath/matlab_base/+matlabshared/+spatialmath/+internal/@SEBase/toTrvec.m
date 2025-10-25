function transl = toTrvec(obj, numTransl)
%This method is for internal use only. It may be removed in the future.

%toTrvec Extract translation from se3 transformation as column vector
%   TRANSL = toTrvec(T) returns the translation in the SE transformation T
%   as column vector, TRANSL.The rotational part of T will be ignored.
%
%   TRANSL = toTrvec(T, NUMTRANSL) returns a matrix of translation vectors
%   with size obj.Dim-by-NUMTRANSL. Translations are repeated until the
%   desired size is reached. This can be helpful in scalar expansion.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    d = obj.Dim;

    % Extract column vectors of translations
    tCols = squeeze(obj.M(1:d-1, d, :));

    if nargin == 2 && numTransl ~= numel(obj)
        % Repeat translation as often as requested
        transl = repmat(tCols,1,numTransl);
    else
        transl = tCols;
    end

end
