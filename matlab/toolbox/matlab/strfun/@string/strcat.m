function t = strcat(varargin)
%

%   Copyright 2016-2023 The MathWorks, Inc.

    % Convert string arguments, replacing <missing> values.
    isScalarMissing = false;
    isNonscalarMissing = false;
    for idx = 1:numel(varargin)
        if isstring(varargin{idx})
            mis = ismissing(varargin{idx});
            if any(mis(:))
                if isscalar(varargin{idx})
                    isScalarMissing = true;
                    varargin{idx} = '';
                else
                    isNonscalarMissing = true;
                    nonscalarMisIdx = mis;
                    str = varargin{idx};
                    str(nonscalarMisIdx) = '';
                    varargin{idx} = cellstr(str);
                end
            else
                varargin{idx} = cellstr(varargin{idx});
            end
        end
    end

    % Use the cell or char method of strcat, converting back to string.
    try
        t = string(strcat(varargin{:}));
    catch e
        throw(e);
    end

    % Restore <missing> values.
    if isScalarMissing
        % Everything is missing.
        t(:) = missing;
    elseif isNonscalarMissing
        % Entire value is missing.
        t(nonscalarMisIdx) = missing;
    end

end
