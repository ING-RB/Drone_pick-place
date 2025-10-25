function data = readall(arrds, varargin)
%READALL   Read all of the data from the ArrayDatastore
%
%   DATA = READALL(ARRDS) returns all of the data in the ArrayDatastore.
%
%       - If "OutputType" is set to "cell", READALL returns an n-by-1 cell
%         array, where n is the number of blocks in the input data array.
%
%       - If "OutputType" is set to "same", READALL returns the original
%         input data.
%
%   DATA = READALL(ARRDS, "UseParallel", TF) specifies whether a parallel
%   pool is used to read all of the data. By default, "UseParallel" is
%   set to false.

%   Copyright 2020 The MathWorks, Inc.

    if matlab.io.datastore.read.validateReadallParameters(varargin{:})
        data = matlab.io.datastore.read.readallParallel(arrds);
        return;
    end

    if arrds.TotalNumBlocks == 0
        if arrds.OutputType == "cell"
            % Make sure that the cell array is set up to grow in the
            % desired ConcatenationDimension.
            indices = computeEmptyCellIndices(arrds);
            data = cell.empty(indices{:});
        else
            data = arrds.Data;
        end
    else
        copyds = copy(arrds);
        reset(copyds);
        copyds.ReadSize = copyds.TotalNumBlocks;
        data = copyds.read();
    end
end


