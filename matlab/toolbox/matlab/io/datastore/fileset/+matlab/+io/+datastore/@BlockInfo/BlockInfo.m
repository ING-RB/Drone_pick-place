classdef BlockInfo < matlab.io.datastore.internal.VectorObjectDisplay
%BLOCKINFO Information about the block within a file
%   BI = matlab.io.datastore.BlockInfo(filenames, fileSizes, offsets, blockSizes)
%   creates a BlockInfo object containing information about the block
%   within the file including file name, file size, offset from the start
%   of the file, and the size of the block.
%
%   BlockInfo Properties:
%
%      Filename  - Name of the file
%      FileSize  - Size of the file
%      Offset    - Offset from the start of the file
%      BlockSize - Size of the block
%
%   Example:
%   --------
%      folder = fullfile(matlabroot,"toolbox","matlab","demos");
%      bs = matlab.io.datastore.BlockedFileSet(folder,"IncludeSubfolders", ...
%          true,"FileExtensions",".mat");
%
%      b1 = nextblock(bs)      % Obtain block information for the first block
%      b2 = nextblock(bs)      % Obtain block information for the second block
%      all1 = bs.BlockInfo     % Obtain block information for all the blocks
%      all2 = bs.BlockInfo(:)  % Obtain block information for all the blocks
%      all3 = bs.BlockInfo()   % Obtain block information for all the blocks
%      b10 = bs.BlockInfo(10)  % Obtain block information for the 10th block
%
%   See also matlab.io.datastore.BlockedFileSet,
%            matlab.io.datastore.FileInfo,
%            matlab.io.datastore.DsFileReader,
%            matlab.io.Datastore.

%   Copyright 2019 The MathWorks, Inc.
    properties (SetAccess = protected)
        Filename (:,1) string
        FileSize (:,1) double
        Offset (:,1) double
        BlockSize (:,1) double
    end

    methods
        function obj = BlockInfo(filenames, fileSizes, offsets, blockSizes)
            if isempty(filenames)
                obj.Filename = string.empty(0,1);
                obj.FileSize = double.empty(0,1);
                obj.Offset = double.empty(0,1);
                obj.BlockSize = double.empty(0,1);
            else
                obj.Filename = filenames;
                obj.FileSize = fileSizes;
                obj.Offset = offsets;
                obj.BlockSize = blockSizes;
            end
        end
    end

    methods (Hidden)
        function disp(obj)
            %DISP controls the display of the BlockInfo.
            buildHeader(obj, 'BlockInfo');
            T = table(obj.Filename, obj.FileSize, obj.Offset, obj.BlockSize, ...
                'VariableNames', {'Filename', 'FileSize', 'Offset', 'BlockSize'});
            displayInfo(obj,T);
        end

        function objSize1 = getSize(obj)
            objSize1 = numel(obj.Filename);
        end

        function throwSizeIndexingError(~, dim)
            if dim ~= 1 && dim ~= 2
                error(message("MATLAB:datastoreio:dsfileset:invalidFileInfoIndex", ...
                    "BlockInfo", "blocks"));
            end
        end

        function obj = constructObj(~, cellArr)
            obj = matlab.io.datastore.BlockInfo(cellArr{1}, cellArr{2}, ...
                cellArr{3}, cellArr{4});
        end

        function n = numArgumentsFromSubscript(~,~,~)
            n = 1;
        end


        function varargout = subsref(blockInfo, subscript)
            switch size(subscript,2)
                case 3
                    % for blockInfo(index1:index2).Property(index3:index4) or
                    % blockInfo(index1:index2).Property or
                    % blockInfo(index1:index2).Property()
                    propertyName = subscript(2).subs;
                    index = subscript(1).subs{1};
                    tempArray = blockInfo.(propertyName)(index);

                    if ~isempty(subscript(3).subs)
                        propIndex = subscript(3).subs{1};
                        varargout = {tempArray(propIndex)};
                    else
                        varargout = {tempArray};
                    end
                case 2
                    % for blockInfo.Property(index1:index2) or
                    % blockInfo(index1:index2).Property
                    if iscell(subscript(1).subs)
                        propertyName = subscript(2).subs;
                        index = getIdxBasedOnSubscript(subscript);
                        tempArray = blockInfo.(propertyName)(index);
                    else
                        propertyName = subscript(1).subs;
                        tempArray = blockInfo.(propertyName);
                        if ~isempty(subscript(2).subs)
                            index = subscript(2).subs{1};
                            tempArray = tempArray(index);
                        end
                    end
                    varargout = {tempArray};
                case 1
                    % indexing into BlockInfo or querying a property on
                    % BlockInfo
                    if iscell(subscript.subs)
                        if numel(subscript.subs) > 2 || (numel(subscript.subs) > 1 ...
                                && subscript.subs{2} ~= 1 && ~strcmp(subscript.subs{2},':'))
                            error(message("MATLAB:datastoreio:dsfileset:invalidFileInfoIndex", ...
                                "BlockInfo", "blocks"));
                        end

                        index = getIdxBasedOnSubscript(subscript);

                        varargout = {matlab.io.datastore.BlockInfo(blockInfo.Filename(index), ...
                            blockInfo.FileSize(index), blockInfo.Offset(index), ...
                            blockInfo.BlockSize(index))};
                    else
                        propName = subscript.subs;
                        varargout = {blockInfo.(propName)};
                    end
            end

            function idx = getIdxBasedOnSubscript(subscript)
                % we need to change the indexing in some cases,
                % e.g. bs.BlockInfo() really means bs.BlockInfo(:)
                if ~isempty(subscript(1).subs)
                    idx = subscript(1).subs{1};
                else
                    idx = ':';
                end
            end
        end
    end

    methods (Hidden, Static)
        function obj = empty(varargin)
            obj = matlab.io.datastore.BlockInfo(string.empty(0,1), ...
                double.empty(0,1), double.empty(0,1), double.empty(0,1));
        end
    end
end
