function varargout = split(str, varargin)
%

%   Copyright 2015-2023 The MathWorks, Inc.

    narginchk(1, 3);
    if ~isTextStrict(str)
        firstInput = getString(message('MATLAB:string:FirstInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    end

    try
        s = string(str);
        [varargout{1:nargout}] = s.split(varargin{:});
        
        if ~isstring(str)
            varargout{1} = cellstr(varargout{1});
            
            if nargout > 1
                varargout{2} = cellstr(varargout{2});
            end
        end
        
    catch E
        throw(E)
    end
end
