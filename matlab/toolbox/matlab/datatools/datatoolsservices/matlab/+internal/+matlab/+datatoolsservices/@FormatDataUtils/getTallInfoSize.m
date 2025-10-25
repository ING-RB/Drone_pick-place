% Calculate a MxNx... or similar size string.  This logic matches similar logic
% for tall variable command line display. Argument is a struct, which contains
% the fields returned from the matlab.bigdata.internal.util.getArrayInfo
% function.

% Copyright 2015-2023 The MathWorks, Inc.

function tallInfoSize = getTallInfoSize(tallInfo)
    if isempty(tallInfo.Size) || isnan(tallInfo.Ndims)
        % No size information at all, MxNx... Use the unicode character for
        % horizontal ellipses
        dimStrs = {'M', 'N', char(8230)};
    else
        % Create a string representation of the size, replacing any NaN's with a
        % replacement letter

        % unknownDimLetters are the placeholders we'll use in the size
        % specification
        unknownDimLetters = 'M':'Z';

        dimStrs = cell(1, tallInfo.Ndims);
        for idx = 1:tallInfo.Ndims
            if isnan(tallInfo.Size(idx))
                if idx > numel(unknownDimLetters)
                    % Array known to be 15-dimensional, but 15th (or higher)
                    % dimension is not known. Not sure how you'd ever hit this.
                    dimStrs{idx} = '?';
                else
                    dimStrs{idx} = unknownDimLetters(idx);
                end
            else
                dimStrs{idx} = num2str(tallInfo.Size(idx));
            end
        end
    end

    % Join together dimensions using the Times symbol.
    tallInfoSize = char(join(dimStrs, internal.matlab.datatoolsservices.FormatDataUtils.TIMES_SYMBOL));
end
