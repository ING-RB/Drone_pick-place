function s = pad(str, varargin)
%

%   Copyright 2015-2023 The MathWorks, Inc.

    narginchk(1, 4);
    
    if ~isTextStrict(str)
        firstInput = getString(message('MATLAB:string:FirstInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    end

    try
        s = string(str);
        
        if nargin == 1
            s = s.pad();
        else
            s = s.pad(varargin{:});
        end
        
        s = convertStringToOriginalTextType(s, str);
        
    catch E
        throw(E)
    end
end
