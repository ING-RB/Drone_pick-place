function s = append(txt,varargin)
%

%   Copyright 2018-2023 The MathWorks, Inc.

    narginchk(1, Inf);
    if ~isTextStrict(txt)
        firstInput = getString(message('MATLAB:string:Input'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    end

    try
        s = string(txt);
        s = s.append(varargin{:});
        
        if ~ischar(txt) || any(cellfun('isclass',varargin,'cell'))
            s = cellstr(s);
        else
            s = char(s);
        end     
    catch E
        throw(E);
    end
end
