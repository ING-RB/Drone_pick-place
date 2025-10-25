function s = replaceBetween(str, start, stop, value, varargin)
%

%   Copyright 2016-2023 The MathWorks, Inc.

    narginchk(4, Inf);
    
    if ~isTextStrict(str)
        error(fillMessageHoles('MATLAB:string:MustBeCharCellArrayOrString',...
                               'MATLAB:string:FirstInput'));
    end

    try
        s = string(str);
        
        if nargin == 4
            s = s.replaceBetween(start, stop, value);
        else
            s = s.replaceBetween(start, stop, value, varargin{:});
        end
        
        s = convertStringToOriginalTextType(s, str);
        
    catch ex
        if strcmp(ex.identifier, 'MATLAB:string:CannotConvertMissingElementToChar')
            error(fillMessageHoles('MATLAB:string:CannotInsertMissingIntoChar',...
                                   'MATLAB:string:MissingDisplayText'));
        end
        ex.throw;
    end
end
