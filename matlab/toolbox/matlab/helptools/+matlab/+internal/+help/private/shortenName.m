function shortName = shortenName(longName)
    shortName = regexp(longName, '\w+$', 'match', 'once');
end

%   Copyright 2022 The MathWorks, Inc.
