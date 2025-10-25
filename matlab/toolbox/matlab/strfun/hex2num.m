function x = hex2num(s)
%

%   Copyright 1984-2023 The MathWorks, Inc.

    if ischar(s)
        x = hex2decImpl(s);
    elseif iscellstr(s)
        x = hex2decImpl(char(s));
    elseif isstring(s)
        x = zeros(size(s));
        for i = 1:numel(s)
            x(i) = hex2decImpl(char(s(i)));
        end
    else
        error(message('MATLAB:hex2num:InputMustBeString'))
    end
end


function num = hex2decImpl(dec)

    if isempty(dec)
        num = [];
        return;
    end

    blanks = find(dec==' '); % Find the blanks at the end
    if ~isempty(blanks)
        dec(blanks) = '0';
    end % Zero pad the shorter hex numbers.

    [row,col] = size(dec);
    d = zeros(row,16);
    % Convert '0':'9' to 0:9;
    d(:,1:col) = abs(lower(dec)) - '0';
    % Compensate for the above to convert 'a':'f' to 10:15.
    d = d - 39.*(d>9);

    if any(d(:) > 15) || any(d(:) < 0)
        error(message('MATLAB:hex2num:OutOfRange'))
    end

    % More than 16 characters are truncated.
    if col > 16
        d(:, col:end) = [];
    end

    num = uint8(d);
    % We assume little endian hence the flip.
    num = flip((16*num(:, 1:2:end) + num(:, 2:2:end)).');
    num = typecast(num(:), 'double');
end
