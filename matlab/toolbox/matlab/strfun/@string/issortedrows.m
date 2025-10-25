function tf = issortedrows(A,varargin)
%

%   Copyright 2016-2023 The MathWorks, Inc.

if ~isstring(A)
    [varargin{:}] = convertStringsToChars(varargin{:});
    tf = issortedrows(A, varargin{:});
else
    [col,dirCodes,missingFlag,scalarExpand] = matlab.internal.math.issortedrowsParseInputs(ismatrix(A),size(A,2),A,varargin{:});
    A = A(:,abs(col));
    if(scalarExpand && ~isempty(dirCodes) && ((dirCodes(1) == 3) || (dirCodes(1) == 6)))
		% If we scalar expanded Monotonic need to check if scalar expand single ascend / descend was true
		dirCodesNew = dirCodes;
        if (dirCodes(1) == 3) 
            dirCodesNew(:) = 1;
        else
            dirCodesNew(:) = 4;
        end
		tf = (matlab.internal.math.issortedrowsFrontToBack(A,dirCodesNew,'MissingPlacement',missingFlag) || matlab.internal.math.issortedrowsFrontToBack(A,dirCodesNew+1,'MissingPlacement',missingFlag));
    else
        % Perform issortedrows check starting with the first specified column and
        % moving on to the next one if ties are present:
        tf = matlab.internal.math.issortedrowsFrontToBack(A,dirCodes,'MissingPlacement',missingFlag);
    end
end
