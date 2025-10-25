function x = stringize(x, fmttypeOrInteractive)
%

%   Copyright 2015-2020 The MathWorks, Inc.

    import matlab.io.spreadsheet.internal.createDatetime;
    unexpCls = {};
    
    fmttype = fmttypeOrInteractive;
    
    if islogical(fmttype)
        if ispc && fmttype
            fmttype = 'osdep';
        else
            fmttype = 'default';
        end
    elseif ~ischar(fmttype)
        error('Invalid fmttype value');
    end
    
    % can do one shot conversion.
    if isnumeric(x)
        % If we hit a complex number, we assume that's supposed to be a
        % datetime.  Right now, you can't "stringize" a complex number as a
        % complex number.
        if isreal(x)
            x = arrayfun(@num2str, x, 'UniformOutput', false);
        else
            strrep(cellstr(createDatetime(x, fmttype, ''), [], 'system'), 'NaT', '');
        end
        return;
    elseif islogical(x)
        c = cell(size(x));
        c(x) = {'true'};
        c(~x) = {'false'};
        x = c;
        return;
    elseif isdatetime(x)
        x = strrep(cellstr(x, [], 'system'), 'NaT', '');
        return;
    end

     if ~iscell(x)
         x = {x};
     end

    % cell at a time conversion.
    for i = 1:length(x)
        y = x{i};
        if isnumeric(y)
            if ~isreal(y) % datetime
                s = char(createDatetime(y, fmttype, ''), [], 'system');
            elseif isnan(y)
                % A numeric NaN means the cell was empty, make that the empty string
                s = '';
            else
                s = num2str(y);
            end
        elseif islogical(y)
            if y
                s = 'true';
            else
                s = 'false';
            end
        elseif ischar(y)
            s = y;
        elseif isdatetime(y) % for external clients
            s = char(y, [], 'system');
        else
            clsy = class(y);
            if ismember(clsy, unexpCls), continue; end
            unexpCls{end+1} = clsy; %#ok<AGROW,NASGU>
            error(message('MATLAB:readtable:UnexpectedClass', clsy));
        end
        x{i} = s;
    end
end
