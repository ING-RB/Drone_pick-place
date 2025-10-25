function s = eraseBetween(str, start, stop, varargin)
%

%   Copyright 2016-2023 The MathWorks, Inc.

    narginchk(3, Inf);
    
    if ~isTextStrict(str)
        firstInput = getString(message('MATLAB:string:FirstInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    end

    try
        s = string(str);
        
        if nargin == 3
            s = s.eraseBetween(start, stop);
        else
            s = s.eraseBetween(start, stop, varargin{:});
        end
        
        s = convertStringToOriginalTextType(s, str);
        
    catch E
        throw(E);
    end
end
