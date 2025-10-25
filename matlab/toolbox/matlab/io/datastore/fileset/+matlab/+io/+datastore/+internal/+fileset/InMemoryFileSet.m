classdef (Sealed) InMemoryFileSet < matlab.io.datastore.internal.fileset.ResolvedFileSet & ...
        matlab.io.datastore.mixin.CrossPlatformFileRoots
%INMEMORYFILESET A simple in-memory FileSet object for collecting files.
%
%   See also datastore, matlab.io.datastore.Partitionable.

%   Copyright 2017 The MathWorks, Inc.
    properties (Access = private)
        %FILES
        Files (:, 1)
        %SCHEMAVERSION
        SchemaVersion string
        %FILENAMESFORTRANSFORM File names to be used during cross platform file
        % roots transformation.
        % This property is not being used currently, but needs to exist for
        % loadobj to work correctly with pre-R2019b DsFileSets.
        FileNamesForTransform = []
    end

    methods (Access = {?matlab.io.datastore.internal.fileset.ResolvedFileSetFactory})
        function fs = InMemoryFileSet(nvStruct)
            fs = fs@matlab.io.datastore.internal.fileset.ResolvedFileSet(nvStruct);
            fs.Files = string(nvStruct.Files);
            reset(fs);
            fields = fieldnames(nvStruct);
            if any(contains(fields,'AlternateFileSystemRoots'))
                fs.AlternateFileSystemRoots = nvStruct.AlternateFileSystemRoots;
            else
                fs.AlternateFileSystemRoots = {};
            end
            fs.SchemaVersion = matlab.io.datastore.internal.getVersionString();
        end
    end

    methods (Hidden)
        function newCopy = copyWithFileIndices(fs, indices, varargin)
            %COPYWITHFILEINDICES This copies the current object using the input indices.
            %   Based on the input indices fileset object creates a copy.
            %   Subclasses must implement on how they can be created from a list of file indices.
            newCopy = copy(fs);
            if ~isempty(indices)
                newCopy.EndOffset = newCopy.FileSizes(indices(end));
            else
                newCopy.EndOffset = 0;
            end
            setFileIndices(newCopy, indices);
            if nargin > 2
                newCopy.NumSplits = varargin{1};
            else
                newCopy.NumSplits = numSplitsForSubset(newCopy, indices);
            end
            reset(newCopy);
        end
        function setShuffledIndices(fs, indices)
            %SETSHUFFLEDINDICES Set the shuffled indices for the fileset object.
            %   Any subsequent nextfile calls to the fileset object gets the files
            %   using the shuffled indices.
            % verify that indices is equal to NumFiles
            if numel(indices) ~= fs.NumFiles || ~isempty(setdiff(1:fs.NumFiles, indices))
                error(message("MATLAB:datastoreio:dsfileset:incorrectShuffledIndices"));
            end
            setFileIndices(fs,indices);
            if ~isempty(fs.BlocksPerFile)
                % splits need to be recalculated to populate BlocksPerFile
                [~, cumSplits] = splitsWithFileSplitSize(fs);
                fs.BlocksPerFile = cumsum(cumSplits);
            end
        end
        function setDuplicateIndices(fs, duplicateIndices, ~)
            %SETDUPLICATEINDICES Set the duplicate indices for the fileset object.
            %   Any subsequent nextfile calls to the fileset object gets the files
            %   using the already existing indices and duplicate indices.
            setFileIndices(fs,duplicateIndices);
            fs.NumFiles = numel(fs.Files);
        end
        function setFilesAndFileSizes(fs, files, fileSizes)
            %SETFILESANDFILESIZES Set the files and file sizes for the fileset object.
            fs.Files = string(files);
            fs.FileSizes = fileSizes;
            fs.EndOffset = fs.FileSizes(end);
            reset(fs);
            if ischar(fs.FileSplitSize)
                setNumSplits(fs, fs.NumFiles);
            else
                [splits, cumSplits] = splitsWithFileSplitSize(fs);
                fs.BlocksPerFile = cumsum(cumSplits);
                if ~isempty(splits) && ~isscalar(splits)
                    numSplits = size(splits,1);
                elseif isscalar(splits) && splits == 0
                    numSplits = 0;
                end
                setNumSplits(fs, numSplits);
            end
        end
        function fs = copyAndOrShuffle(fs, indices)
            %COPYANDORSHUFFLE This copies the current object, with or without shuffling.
            %   Based on the inputs fileset object can decide to either copy
            %   and/or shuffle the fileset. If just shuffling is done, then the output
            %   of this function is empty since a copy is not created.
            setFileIndices(fs, indices);
            fs.NumFiles = numel(indices);
        end
        function s = saveobj(fs)
            %SAVEOBJ Specific to CompressedFileSet this saves all to a struct.
            %   Get all the properties using a struct constructor and save the
            %   CompressedFileSet as a shallow copy. This needs to serialize
            %   the internal paths object as well, that will be loaded on loadobj.
            [lastWarnMsg,lastWarnId] = lastwarn;
            warningId = 'MATLAB:structOnObject';
            onState = warning('off', warningId);
            c = onCleanup(@() matlab.io.datastore.internal.fileset.ResolvedFileSet.iCleanupWarnOnSave(onState, lastWarnMsg, lastWarnId));

            s = struct(fs);
            s.InMemoryFileSet = fs;
        end
    end

    methods (Static, Hidden)
        function fs = loadobj(s)
            %LOADOBJ Specific to CompressedFileSet that loads all from a struct.
            %   Get all the properties from a struct saved during saveobj.
            %   CompressedFileSet is a shallow copy, so set all the relevant properties.
            %   This needs to deserialize the internal paths object as well,
            %   using the serialized properties saved during saveobj.
            if isstruct(s)
                % objects saved after 17b
                fs = s.InMemoryFileSet;
                m = meta.class.fromName('matlab.io.datastore.internal.fileset.InMemoryFileSet');
                constProps = {m.PropertyList([m.PropertyList.Constant]).Name};
                propsToRemove = [constProps, {'InMemoryFileSet','SetFromLoadObj'}];

                s = rmfield(s, propsToRemove);
                fields = fieldnames(s);
                c = onCleanup(@()setDefaultsFromLoadObj(fs));
                fs.SetFromLoadObj = true;
                for i = 1:numel(fields)
                    fs.(fields{i}) = s.(fields{i});
                end
                replaceUNCPaths(fs);
            else
                fs = s;
            end
        end
    end

    methods (Access = private)
        function setDefaultsFromLoadObj(fs)
            defaultSetFromLoadObj(fs);
        end
    end
    methods (Access = protected)
        function setFileIndices(fs, indices)
            %SETFILEINDICES A helper to set the indices for files and file sizes.
            fs.Files = fs.Files(indices);
            fs.FileSizes = fs.FileSizes(indices);
        end

        function [files, fileSizes] = resolveAll(fs, varargin)
            if nargin > 1
                files = getFilesAsCellStr(fs, varargin{:});
                files = string(files);
                fileSizes = fs.FileSizes(varargin{:});
            else
                files = getFilesAsCellStr(fs, 1:fs.NumFiles);
                files = string(files);
                fileSizes = fs.FileSizes;
            end
        end

        function f = resolveFile(fs)
            f = fs.Files(fs.CurrentFileIndex);
        end

        function files = getFilesAsCellStr(fs, ii)
            % Implementation to obtain a column cell array of files
            % that can be obtained from the fileset object.
            files = cellstr(fs.Files(ii));
        end

        function tf = isEmptyFiles(fs)
            tf = fs.NumFiles == 0;
        end

        function setTransformedFiles(fs, files)
            fs.Files = files;
            fs.FileNamesForTransform = [];
        end

        function files = getFilesForTransform(fs)
            files = fs.Files;
        end
    end
end
