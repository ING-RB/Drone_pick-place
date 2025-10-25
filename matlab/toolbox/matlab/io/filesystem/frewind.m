function frewind(fid)
    narginchk(1, 1);

    status = fseek(fid, 0, -1);
    if (status == -1)
        error (message('MATLAB:frewind:Failed'))
    end
end

%   Copyright 1984-2023 The MathWorks, Inc.
