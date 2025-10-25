% Returns the size string

% Copyright 2015-2023 The MathWorks, Inc.

function szz = getSizeString(value)
    import internal.matlab.datatoolsservices.FormatDataUtils;
    s = FormatDataUtils.getVariableSize(value);
    try
        if isa(value, 'tall')
            % Special handling for tall variables, because the size of a tall
            % variable may not be known.
            tallInfo = matlab.bigdata.internal.util.getArrayInfo(value);
            szz = internal.matlab.datatoolsservices.FormatDataUtils.getTallInfoSize(tallInfo);
        elseif isscalar(s) && s == 0
            szz = '0';
        elseif isnumeric(s)
            if isa(value, 'matlab.mixin.internal.CustomSizeString')
                % This class creates a custom size string for whos, so we need
                % to use the same value.
                w = whos('value');
                s = w.size;
            end
            if length(s) <= FormatDataUtils.NUM_DIMENSIONS_TO_SHOW
                szz = char(join(string(s), FormatDataUtils.TIMES_SYMBOL));
            else
                szz = sprintf('%d-D', length(s));
            end
        elseif usejava('jvm') && isjava(s)
            szz = ['1' FormatDataUtils.TIMES_SYMBOL '1'];
        else
            szz = char(s);
        end
    catch
        % Show "1x1" if there's an error (which can happen when an object is
        % open in the editor, and an error is inserted)
        szz = ['1' FormatDataUtils.TIMES_SYMBOL '1'];
    end
end
