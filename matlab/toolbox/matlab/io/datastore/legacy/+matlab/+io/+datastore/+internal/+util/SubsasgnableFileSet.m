classdef (Hidden, Abstract) SubsasgnableFileSet < handle
%SUBSASGNABLEFILESET Abstraction layer to subsasgn Files using DsFileSet.
%   Settting Files on a DsFileSet is not allowed but there are some hidden methods,
%   that can accomplish this (with care) providing better performance:
%       - setDuplicateIndexes: Set some files to be duplicate using indices.
%                              Eg. ds.Files = repelem(ds.Files,5,1);
%                              Eg. ds.Files(end+1:end+10) = ds.Files(1:10);
%       - copyWithFileIndices: Get a copy of the fileset using some repetitive or
%                              non-repetitive but ordered indices.
%                              Eg. ds.Files = ds.Files([1 1 1 4 4 5]);
%                              Another use is to empty out some files.
%                              Eg. ds.Files(1:10) = [];% when ds has more than 10 files
%       - copyAndOrShuffle   : Get a copy with file indices and shuffle if needed.
%                              Copy and shuffle
%                                - empty out some files and add duplicates
%                                  Eg. ds.Files(end-9:end) = ds.Files(1:10);
%                              Shuffle only
%                                - Eg. ds.Files = ds.Files(randperm(numel(ds.Files)));
%                                - Eg. ds.Files = ds.Files;
%                              Emptied out some files not using empty on rhs
%                                - Eg. ds.Files = ds.Files(1);
%                              Different labels. Bring larger index of a different label first.
%                                - Eg.,
%                                  ds = imageDatastore({'street1.jpg', 'street2.jpg', 'corn.tif', 'peppers.png'});
%                                  ds.Files = ds.Files([4,1])
%
%   See also audioDatastore,
%            matlab.io.datastore.ImageDatastore,
%            matlab.io.datastore.ParquetDatastore.

%   Copyright 2018 The MathWorks, Inc.

    properties (Access = protected)
        %EMPTYINDEXES
        % This is used to empty out file indices that are not needed in
        % FileSet. On subsasgn'ing Files with [], we need a way to subsasgn
        % other properties that are in one-2-one mapping with Files.
        % Example: Labels property to [].
        EmptyIndexes
        %ADDEDINDEXES
        % This is used to add file indices from existing ones that are part of
        % FileSet. On subsasgn'ing Files with more files, we need a way to subsasgn
        % other properties that are in one-2-one mapping with Files.
        % Example: Labels property to default values.
        AddedIndexes
        %FILESASSIGNED
        % On assigning Files with more files, we need a way to subsasgn
        % other properties that are in one-2-one mapping with Files.
        % Example: Labels property to default values.
        FilesAssigned = false
        %CACHEALLFILES
        % Logical indicating whether to cache all files or not.
        CacheAllFiles = false
        %NUMFILES
        % Whenever we set files, determine number of files instead of
        % calling numel all the time (reset method).
        NumFiles
    end

    properties (Access = protected, Transient, NonCopyable)
        %NOOPDURINGGETDOTFILES
        % Set only during display to indicate we don't need
        % get.Files method to get the actual files but be a no-op.
        NoOpDuringGetDotFiles = false
        %ALLFILESCACHED
        % All files cached when CacheAllFiles is true.
        AllFilesCached = []
    end

    methods (Abstract, Access = protected)
        [diffIndexes, currIndexes, files, fileSizes, diffPaths] = setNewFilesAndFileSizes(ds, files);
        setFileSet(ds, fileset);
        fileset = getFileSet(ds);
    end

    methods
        %RESET Reset the datastore to the start of the data.
        %   RESET(DS) resets DS to the beginning of the datastore.
        %
        %   Example:
        %   --------
        %      folders = fullfile(matlabroot,'toolbox','matlab',{'demos','imagesci'});
        %      exts = {'.jpg','.png','.tif'};
        %      imds = imageDatastore(folders,'FileExtensions',exts);
        %
        %      while hasdata(imds)
        %          img = read(imds);      % Read the images
        %          imshow(img);           % See images in a loop
        %      end
        %      reset(imds);               % Reset to the beginning of the datastore
        %      img = read(imds)           % Read from the beginning
        %
        %   See also imageDatastore, read, hasdata, readall, preview.
        function reset(ds)
            fileset = getFileSet(ds);
            reset(fileset);
            % set NumFiles so not to calculate whenever numel of files is needed.
            ds.NumFiles = getNumFiles(ds);
            ds.NoOpDuringGetDotFiles = false;
        end
    end

    methods (Access = protected)
        function [diffIndexes, currIndexes, files, fileSizes, diffPaths] = setFilesOnFileSet(ds, files)
            fileset = getFileSet(ds);
            [diffIndexes, currIndexes, files, fileSizes, diffPaths] = setNewFilesAndFileSizes(ds, files);
            if isempty(diffPaths)
                if isempty(ds.AddedIndexes)
                    if numel(currIndexes) <= getNumFiles(ds)
                        % Copy and shuffle
                        %   empty out some files and add duplicates
                        %   eg. ds.Files(end-9:end) = ds.Files(1:10);
                        % Shuffle only
                        %   eg. ds.Files = ds.Files(randperm(numel(ds.Files)));
                        %   eg. ds.Files = ds.Files;
                        % emptied out some files not using empty on rhs
                        % eg. ds.Files = ds.Files(1);

                        % Different labels. Bring larger index of a different label first.
                        %  eg., ds = imageDatastore({'street1.jpg', 'street2.jpg', 'corn.tif', 'peppers.png'});
                        %       ds.Files = ds.Files([4,1])
                        setFileIndices(ds, currIndexes, fileset, 'copyAndOrShuffle');
                    else
                        % eg. ds.Files = repelem(ds.Files,5,1);
                        ds.AddedIndexes = 1:numel(currIndexes) > getNumFiles(ds);
                        setDuplicateIndices(fileset, currIndexes, ds.AddedIndexes);
                        setFileSet(ds, fileset);
                    end
                elseif ~isempty(ds.EmptyIndexes)
                    % emptied out some files
                    % eg. ds.Files(1:10) = [];% when ds has more than 10 files
                    setFileIndices(ds, currIndexes, fileset);
                else
                    % duplicate paths
                    % eg. ds.Files(end+1:end+10) = ds.Files(1:10);
                    setDuplicateIndices(fileset, currIndexes, ds.AddedIndexes);
                    setFileSet(ds, fileset);
                end
            else
                % The case where new files are added. Currently, this is not a very
                % common use case when you have millions of files. So fall back to
                % in memory file set.
                files(diffIndexes) = diffPaths;
                import matlab.io.datastore.internal.fileset.ResolvedFileSetFactory;
                fileset = ResolvedFileSetFactory.buildInMemory(files, fileSizes);
                setFileSet(ds, fileset);
            end
            reset(ds);
        end

        function numFiles = getNumFiles(ds)
            fileset = getFileSet(ds);
            numFiles = fileset.NumFiles;
        end

        function subsasgnPreamble(ds, S, B)
            % Store the indexes of added and emptied files.
            %   - AddedIndexes are used to add duplicate file indices.
            %   - EmptiedIndexes are used to empty out file indices.

            switch numel(S)
                case 2
                    if isequal(S(1).type, '.')
                        switch S(1).subs
                            case 'Files'
                                if isempty(B)
                                    ds.EmptyIndexes = S(2).subs{1};
                                else
                                    idxes = S(2).subs{1};
                                    ds.AddedIndexes = idxes(idxes > getNumFiles(ds));
                                end
                                % Cache files when assignment happens
                                ds.CacheAllFiles = true;
                            otherwise
                                mc = metaclass(ds);
                                prop = findobj(mc.PropertyList,'Name',S(1).subs);
                                if ~isempty(prop) && ~strcmp(prop.SetAccess, 'public')
                                    error(message('MATLAB:class:SetProhibited',prop.Name,class(ds)));
                                end
                        end
                    end
                case 1
                    if isequal(S.type, '.')
                        switch S.subs
                            case 'Files'
                                ds.FilesAssigned = true;
                                % Cache files when subsref and subsasgn happen
                                ds.CacheAllFiles = true;
                            otherwise
                                mc = metaclass(ds);
                                prop = findobj(mc.PropertyList,'Name',S.subs);
                                if ~isempty(prop) && ~strcmp(prop.SetAccess, 'public')
                                    error(message('MATLAB:class:SetProhibited',prop.Name,class(ds)));
                                end
                        end
                    end
            end
        end

        function initializeSubsAsgnIndexes(ds)
            % subsasgn for Files is called before setFilesOnFileSet.
            % reset EmptyIndexes and AddedIndexes if there's an error,
            % so we don't change the Files property or any dependent
            % property like Labels.
            ds.EmptyIndexes = [];
            ds.AddedIndexes = [];
            ds.FilesAssigned = false;
        end

        function setFileIndices(ds, indexes, fileset, ~)
            %SETFILEINDICES Based on nargin set or copy or shuffle the fileset object
            % All of these cases and their examples are part of the comments in
            % setFilesOnFileSet
            switch nargin
                case 2
                    setShuffledIndices(getFileSet(ds), indexes);
                case 3
                    f = copyWithFileIndices(fileset, indexes);
                    setFileSet(ds, f);
                case 4
                    f = copyAndOrShuffle(fileset, indexes);
                    if ~isempty(f)
                        setFileSet(ds, f);
                    end
            end
        end

        function initWithIndices(ds, indexes, varargin)
            %INITWITHINDICES Initialize datastore with specific file indexes.
            %   This can be used to initialize the datastore with ReadFcn and files/fileSizes
            %   found previously or already existing in the splitter information.

            setFileIndices(ds, indexes, varargin{:});
            reset(ds);
        end

        function initializeCachedFiles(ds)
            % Reset AllFilesCached and CacheAllFiles at the end of
            % subsasgn or if there's an error.
            ds.AllFilesCached = [];
            ds.CacheAllFiles = false;
        end

        function files = getFilesAsCellStrAndCache(ds)
            if ds.NoOpDuringGetDotFiles
                % This is for displayScalarObject's getPropertyGroup
                % not incur getting all the files. We just need 3 files.
                files = {};
                return;
            end
            if isempty(ds.AllFilesCached)
                % In case the files are not cached get it from splitter.
                fileset = getFileSet(ds);
                files = getFiles(fileset, 1:fileset.NumFiles);
            else
                files = ds.AllFilesCached;
            end
            if ds.CacheAllFiles
                % If asked to cache all files, store them.
                ds.AllFilesCached = files;
            end
        end

        function [cpy, files] = getCopyWithOriginalFiles(ds)
            %GETCOPYWITHORIGINALFILES A helper to get a datastore copy and the
            % original fileset object.
            cpy = copy(ds);
            files = getFileSet(ds);
        end
    end % methods

end % classdef
