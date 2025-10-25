function labels = validateNonTableLabels(labels, numFiles, fcnName)
%VALIDATENONTABLELABELS Validate labels for non-table values.
%   Non-table LABELS must be a cell array of character vectors,
%   a string array, or a vector of numeric, logical, or categorical type.
%
%   See also matlab.io.datastore.ImageDatastore/Labels.

%   Copyright 2018 The MathWorks, Inc.
    labels = convertStringsToChars(labels);
    if isequal(class(labels),'char')
        labels = cellstr(labels);
    end
    if iscell(labels)
        if isempty(labels)
            return;
        end
        if ~iscellstr(labels)
            error(message('MATLAB:datastoreio:imagedatastore:labelsNotCellstr'));
        end
    end
    classes = {'numeric', 'cell', 'categorical', 'logical'};
    attrs = {'numel', numFiles};
    validateattributes(labels, classes, attrs, fcnName, 'Labels');
    labels = labels(:);
end
