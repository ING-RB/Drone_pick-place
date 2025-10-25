function s = extract(str, pat)
%

%   Copyright 2016-2023 The MathWorks, Inc.

    narginchk(2, 2);
    if ~isTextStrict(str)
        firstInput = getString(message('MATLAB:string:FirstInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    end

    try
        s = string(str);
        s = s.extract(pat);

        if ~isstring(str)
            s = cellstr(s);
        end
        
    catch E
        throw(E);
    end
end

function tf = isTextStrict(value)
    tf = (ischar(value) && ((isempty(value) && isequal(size(value),[0 0])) || isrow(value))) || isstring(value) || iscellstr(value);
end
