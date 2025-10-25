function s = strip(str, varargin)
%

%   Copyright 2016-2023 The MathWorks, Inc.

    narginchk(1, 3);
    
    if ~isTextStrict(str)
        firstInput = getString(message('MATLAB:string:FirstInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    end

    try
        s = string(str);
        
        if nargin == 1
            s = s.strip();
        else
            s = s.strip(varargin{:});
        end
        
        s = convertStringToOriginalTextType(s, str);
        
    catch E
        throw(E)
    end
end
