function tf = formatIsAllString(format)
%Check all detected formats create string types
% i.e.: %q, %s,%[...] %[^...] or %C

%   Copyright 2015-2022 The MathWorks, Inc.

fmt_str = matlab.iofun.internal.formatParser(format);
% check only readable formats because we care about output types.
used_formats = unique(fmt_str.Format(~fmt_str.IsSkipped));
tf = true;
for i = 1:numel(used_formats)
    % string, quoted string, both character sets,
    % fixed width, or categorical fields can be read
    % both ways, don't ignore the first line if all
    % the fields were of these types
    if ~any(used_formats{i}(end)=='sq]Cc')
        tf = false;
        break
    end
end
end
