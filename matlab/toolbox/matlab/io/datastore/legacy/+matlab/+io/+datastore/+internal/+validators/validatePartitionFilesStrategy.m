function [isFilesStrategy, index] = validatePartitionFilesStrategy(partitionStrategy, index, getFilesFcn, numFiles)
%VALIDATEPARTITIONFILESSTRATEGY Validate "Files" strategy inputs for partition method.
%
%   See also matlab.io.datastore.TabularTextDatastore/partition.

%   Copyright 2018 The MathWorks, Inc.
    narginchk(3,4);
    isFilesStrategy = true;
    if ~ischar(partitionStrategy) || ~strcmpi(partitionStrategy, 'Files')
        isFilesStrategy = false;
        return;
    end
    % Input checking
    validateattributes(index, {'double', 'char'}, {}, 'partition', 'Index');
    if ischar(index)
        filename = index;
        validateattributes(filename, {'char'}, {'nonempty', 'row'}, 'partition', 'Filename');

        files = getFilesFcn();
        index = find(strcmp(files, filename));
        if isempty(index)
            error(message('MATLAB:datastoreio:splittabledatastore:invalidPartitionFile', filename));
        end

        if numel(index) > 1
            error(message('MATLAB:datastoreio:splittabledatastore:ambiguousPartitionFile', filename));
        end
    else
        if nargin == 3
            files = getFilesFcn();
            numFiles = numel(files);
        end
        validateattributes(index, {'double'}, {'scalar', 'positive', 'integer'}, 'partition', 'Index');
        if index > numFiles
            error(message('MATLAB:datastoreio:splittabledatastore:invalidPartitionIndex', index));
        end
    end
end
