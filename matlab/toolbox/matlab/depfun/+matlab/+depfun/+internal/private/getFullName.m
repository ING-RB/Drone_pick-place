function s = getFullName(mt, id, dotIDs)
%

%   Copyright 2018-2020 The MathWorks, Inc.

    n1 = select(mt, id);
    d = trueparent(n1);
    
    n1dot = false;
    while ~isempty(d) && any(dotIDs == indices(d))
        n1 = d;
        n1dot = true;
        d = trueparent(n1);
    end
    % tree2str is approximately 100 times slower than string, so
    % use string when feasible. (But don't call iskind(n1,dot) because
    % that is EVEN MORE expensive that tree2str.)
    if n1dot
        s = tree2str(n1);
    else
        s = string(n1);
    end
end

% LocalWords:  iskind
