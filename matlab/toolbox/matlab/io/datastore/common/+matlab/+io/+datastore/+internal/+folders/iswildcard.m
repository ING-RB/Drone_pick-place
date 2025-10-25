function tf = iswildcard(location)
%ISWILDCARD   returns an array of logical values which are true when
%the input contains wildcard characters. 

%   Copyright 2019 The MathWorks, Inc.

    % Check for "*" in the location input.
    tf = contains(location, "*");
end
