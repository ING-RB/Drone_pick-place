function rev = reverse(s)
%

%   Copyright 2015-2023 The MathWorks, Inc.

    narginchk(1, 1);

    try
        if iscell(s)
            rev = cell(size(s));
            for idx = 1:numel(s)
                rev{idx} = charReverse(s{idx});
            end
        else
            rev = charReverse(s);
        end
    catch E
        throw(E)
    end
end

function crev = charReverse(s)

    if ~ischar(s) || (~isempty(s) && ~isrow(s))
        firstInput = getString(message('MATLAB:string:FirstInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    end
    crev = fliplr(s);

end
