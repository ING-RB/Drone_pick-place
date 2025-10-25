function s = compose(fmt, varargin)
%

%   Copyright 2015-2023 The MathWorks, Inc.

    narginchk(1, Inf);
    if ~isTextStrict(fmt)
        firstInput = getString(message('MATLAB:string:FirstInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    end

    try
        s = string(fmt);
        s = s.compose(varargin{:});
        
        if ~isstring(fmt)
            s = cellstr(s);
        end
        
    catch E
        throw(E);
    end
end
