classdef FileInfo < matlab.io.datastore.internal.VectorObjectDisplay
%FILEINFO Information about the file including file name and file size
%   FI = matlab.io.datastore.FileInfo(filenames, fileSizes) creates a
%   FileInfo object containing file names and file sizes
%
%   FileInfo Properties:
%
%      Filename - Name of the file
%      FileSize - Size of the file
%
%   Example:
%   --------
%      folder = fullfile(matlabroot,"toolbox","matlab","demos");
%      fs = matlab.io.datastore.FileSet(folder,"IncludeSubfolders",true, ...
%          "FileExtensions",".mat");
%
%      fInfo1 = nextfile(fs)  % Obtain file information for the first file
%      fInfo2 = nextfile(fs)  % Obtain file information for the second file
%      all1 = fs.FileInfo     % Obtain file information for all the files
%      all2 = fs.FileInfo(:)  % Obtain file information for all the files
%      all3 = fs.FileInfo()   % Obtain file information for all the files
%      f10 = fs.FileInfo(10)  % Obtain file information for the 10th file
%
%   See also matlab.io.datastore.FileSet,
%            matlab.io.datastore.BlockInfo,
%            matlab.io.datastore.DsFileReader,
%            matlab.io.Datastore.

%   Copyright 2019-2020 The MathWorks, Inc.

    properties (SetAccess = protected)
        Filename (:,1) string
        FileSize (:,1) double
    end

    methods
        function obj = FileInfo(filenames, fileSizes)
            if isempty(filenames)
                obj.Filename = string.empty(0,1);
                obj.FileSize = double.empty(0,1);
            else
                obj.Filename = filenames;
                obj.FileSize = fileSizes;
            end
        end
    end

    methods (Hidden)
        function disp(obj)
            %DISP controls the display of the FileInfo.
            buildHeader(obj, 'FileInfo');
            T = table(obj.Filename, obj.FileSize, 'VariableNames', ...
                {'Filename', 'FileSize'});
            displayInfo(obj,T);
        end

        function objSize1 = getSize(obj)
            objSize1 = numel(obj.Filename);
        end

        function throwSizeIndexingError(~, dim)
            if dim ~= 1 && dim ~= 2
                error(message("MATLAB:datastoreio:dsfileset:invalidFileInfoIndex", ...
                    "FileInfo", "files"));
            end
        end

        function obj = constructObj(~, cellArr)
            obj = matlab.io.datastore.FileInfo(cellArr{1}, cellArr{2});
        end

        function varargout = subsref(fileInfo, subscript)
            switch size(subscript,2)
                case 3
                    % for fileInfo(index1:index2).Property(index3:index4) or
                    % fileInfo(index1:index2).Property or
                    % fileInfo(index1:index2).Property()
                    propertyName = subscript(2).subs;
                    index = subscript(1).subs{1};
                    tempArray = fileInfo.(propertyName)(index);
                    if ~isempty(subscript(3).subs)
                        propIndex = subscript(3).subs{1};
                        varargout = {tempArray(propIndex)};
                    else
                        varargout = {tempArray};
                    end
                case 2
                    % for fileInfo.Property(index1:index2) or
                    % fileInfo(index1:index2).Property
                    if iscell(subscript(1).subs)
                        propertyName = subscript(2).subs;
                        index = subscript(1).subs{1};
                        tempArray = fileInfo.(propertyName)(index);
                    else
                        propertyName = subscript(1).subs;
                        tempArray = fileInfo.(propertyName);
                        if ~isempty(subscript(2).subs)
                            index = subscript(2).subs{1};
                            tempArray = tempArray(index);
                        end
                    end
                    varargout = {tempArray};
                case 1
                    % indexing into FileInfo or querying a property on
                    % FileInfo
                    errMsg = "MATLAB:datastoreio:dsfileset:invalidFileInfoIndex";
                    if iscell(subscript.subs)
                        if numel(subscript.subs) > 2 || (numel(subscript.subs) > 1 ...
                                && subscript.subs{2} ~= 1 && ~strcmp(subscript.subs{2},':'))
                            error(message(errMsg, "FileInfo", "files"));
                        end

                        if isempty(subscript.subs)
                            if subscript.type == "()"
                                % accept functional notation here
                                index = ':';
                            else
                                % error for all other inputs
                                error(message(errMsg, "FileInfo", "files"));
                            end
                        else
                            % check if logical indices were passed
                            index = subscript.subs{1};
                            logicalIndexing = islogical(index);
                            if logicalIndexing
                                if numel(index) ~= size(fileInfo,1)
                                    % logical vector passed in does not
                                    % match size of FileInfo, error
                                    error(message(errMsg, "FileInfo", "files"));
                                else
                                    index = find(index ~= 0);
                                end
                            elseif matlab.internal.datatypes.isIntegerVals(...
                                    index, 1, size(fileInfo,1))
                                % numerical indices were passed
                                index = double(index);
                            elseif ~((ischar(index) || isstring(index)) && ...
                                    index == ":")
                                % invalid index supplied to FileInfo
                                error(message(errMsg, "FileInfo", "files"));
                            end
                        end
                        varargout = {matlab.io.datastore.FileInfo(...
                            fileInfo.Filename(index), ...
                            fileInfo.FileSize(index))};
                    else
                        propName = subscript.subs;
                        varargout = {fileInfo.(propName)};
                    end
            end
        end
    end

    methods (Hidden, Static)
        function obj = empty(varargin)
            obj = matlab.io.datastore.FileInfo(string.empty(0,1), double.empty(0,1));
        end
    end
end