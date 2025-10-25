function [wasEmpty, varargout] = validatePrototypeBetweenBlocks(fcn, wasEmpty, varargin)
%validatePrototypeBetweenBlocks Check that small sizes and type of
%empty prototypes match between multiple blocks of the result of FCN:
%cell2mat, cellfun, or arrayfun.
% Verify that size and type match between multiple blocks keeping track of
% empty blocks. If all of the blocks were marked as empty, treat them as an
% empty input and vertically concatenate all of them. If some of them were
% empty, discard them and vertically concatenate the rest of data blocks.

%   Copyright 2019-2024 The MathWorks, Inc.

numOutputs = nargout - 1;
varargout = cell(1, numOutputs);
for ii = 1:numOutputs
    emptyProto = varargin{ii};
    if any(wasEmpty) && ~all(wasEmpty)
        % If there is a combination of empty blocks and data blocks, remove
        % the empty prototype of the empty blocks.
        emptyProto = emptyProto(~wasEmpty);
        wasEmpty = false;
    else
        wasEmpty = all(wasEmpty);
    end
    firstType = class(emptyProto{1});
    for k = 2:size(emptyProto, 1)
            kthType = class(emptyProto{k});
        if ~strcmp(kthType, firstType)
            if fcn == "cell2mat"
                error(message('MATLAB:cell2mat:MixedDataTypes'));
            else
                if (firstType == "missing" || kthType == "missing") ...
                        && iCanConcatenate(emptyProto{1}([]), emptyProto{k}([]))
                    % We ignore missing in cases where that missing
                    % vanishes in the concatenation.
                    continue;
                end
                % cellfun, arrayfun
                error(message('MATLAB:bigdata:array:FunFunMismatchInOutputTypes', ...
                    ii, firstType, class(emptyProto{k})));
            end
        end
    end
    % For CELL2MAT make sure we are not lazily creating a strong type.
    if fcn == "cell2mat" ...
            && ismember(firstType, matlab.bigdata.internal.adaptors.getStrongTypes())
        error(message("MATLAB:bigdata:array:Cell2MatUnsupportedStrongType", ...
                    firstType));
    end
    % Vertcat emptyProto from data blocks to verify size.
    varargout{ii} = {cat(1, emptyProto{:})};
end
end

function tf = iCanConcatenate(a, b)
% Return true if and only if it's possible to vertically concatenate the
% given input arguments.
try
    cat(1, a, b);
    tf = true;
catch err
    tf = false;
end
end