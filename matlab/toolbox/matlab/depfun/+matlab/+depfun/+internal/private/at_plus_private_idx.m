function idx = at_plus_private_idx(apath)
%This function finds the first '/+' or '/@' or '/private' in the given path.

%   Copyright 2016-2020 The MathWorks, Inc.

    if ismac
        % Temp directories start with '/private/' on Mac.
        pat = '(?!^[/\\]private[/\\].+)[/\\]([@+]|private[/\\]).*';
    else
        pat = '[/\\]([@+]|private[/\\]).*';
    end
    idx = regexp(apath, pat, 'ONCE');
end
