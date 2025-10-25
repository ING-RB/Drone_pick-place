function s = join(str, varargin)
%

%   Copyright 2015-2023 The MathWorks, Inc.

    narginchk(1, 3);
    if ~isTextStrict(str)
        firstInput = getString(message('MATLAB:string:FirstInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    end
    
    try
        s = string(str);
        s = s.join(varargin{:});

        if ischar(str)
            s = str;
        elseif ~isstring(str)
            s = cellstr(s);
        end
    catch E
        throw(E);
    end
end
