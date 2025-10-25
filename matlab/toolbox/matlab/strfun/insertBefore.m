function s = insertBefore(str, pos, text)
%

%   Copyright 2016-2023 The MathWorks, Inc.

    narginchk(3, 3);
    
    if ~isTextStrict(str)
        error(fillMessageHoles('MATLAB:string:MustBeCharCellArrayOrString',...
                               'MATLAB:string:FirstInput'));
    end

    try
        s = string(str);
        s = s.insertBefore(pos, text);
        s = convertStringToOriginalTextType(s, str);
        
    catch ex
        if strcmp(ex.identifier, 'MATLAB:string:CannotConvertMissingElementToChar')
            error(fillMessageHoles('MATLAB:string:CannotInsertMissingIntoChar',...
                                   'MATLAB:string:MissingDisplayText'));
        end
        ex.throw;
    end

end
