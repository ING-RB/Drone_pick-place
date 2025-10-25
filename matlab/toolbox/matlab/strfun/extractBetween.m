function s = extractBetween(str, start, stop, varargin)
%

%   Copyright 2016-2023 The MathWorks, Inc.

    narginchk(3, Inf);
    if ~isTextStrict(str)
        firstInput = getString(message('MATLAB:string:FirstInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    end

    try
        s = string(str);
        s = s.extractBetween(start, stop, varargin{:});
        
        if ~isstring(str)
            s = cellstr(s);
        end
        
    catch E
        throw(E);
    end
end
