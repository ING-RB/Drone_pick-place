function S = parseDirListingForQNX(listing, namesOnly)
%PARSEDIRLISTINGFORQNX Parse LIST or NLST output from Unix QNX FTP servers

% Copyright 2020 The MathWorks, Inc.
    if namesOnly
        % if only names are needed, return early from here, let UNIX parser
        % take care of this case
        S = [];
        return;
    end

    if startsWith(listing, "total")
        % skip this line
        S = splitlines(listing);
        S = S(2:end);
        if isempty(S{end})
            S(end) = [];
        end
        listing = join(string(S), newline);
    end
    % apply a different textscan parse
    parts = textscan(listing, "%s%d%s%d%3c%d%s%[^\r\n]", ...
        "MultipleDelimsAsOne", true);
    if ~all(cellfun(@(x)size(x,1), parts))
        % QNX parsing did not work, revert to UNIX parsing
        S = [];
    else
        S = struct("MonthName", {string(parts{5})}, "Day", {string(parts{6})}, ...
            "YearOrTime", {string(parts{7})}, "Names", parts(8), "Bytes", ...
            parts(4), "Parts", {parts});
    end
end