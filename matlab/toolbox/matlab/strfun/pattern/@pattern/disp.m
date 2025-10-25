function disp(pat,name)
%

%   Copyright 2020 The MathWorks, Inc.

    narginchk(1,2);

    if nargin == 1
        name = inputname(1);
    end

    dispImpl(pat,name);
end
