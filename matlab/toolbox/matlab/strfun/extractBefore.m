function s = extractBefore(str, pos)
%

%   Copyright 2016-2023 The MathWorks, Inc.

    narginchk(2, 2);
    if ~isTextStrict(str)
        firstInput = getString(message('MATLAB:string:FirstInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    end

    try
        s = string(str);
        s = s.extractBefore(pos);
        s = convertStringToOriginalTextType(s, str);
        
    catch E
        throw(E);
    end
end
