classdef FoldersPropertyProvider < handle
%FoldersPropertyProvider   Declares the interface that provides the Folders
%   property for use in datastore writeall.
%   This class is a mixin for subclasses of matlab.io.Datastore that adds
%   folder replication support to the datastore.
%
%   FoldersPropertyProvider Properties:
%
%   Folders              - List the folders that contain data in the
%                          datastore.
%
%   FoldersPropertyProvider Property Attributes
%
%   Folders              - SetAccess = Protected, GetAccess = Public
%
%   FoldersPropertyProvider Methods:
%   
%   populateFoldersFromLocation - Populate the Folders property from the
%                                 location input provided to the datastore.
%
%   FoldersPropertyProvider Method Attributes:
%
%   populateFoldersFromLocation - Protected
%   
%   This class provides a default implementation for the
%   populateFoldersFromLocation method that can be used as a convenience
%   function to populate the Folders property in a similar manner as
%   built-in datastores like ImageDatastore and TabularTextDatastore.

%   Copyright 2019-2023 The MathWorks, Inc.

    properties (SetAccess = {?matlab.io.datastore.FoldersPropertyProvider, ...
                             ?matlab.io.datastore.mixin.CrossPlatformFileRoots})
        %Folders    lists the folders provided in the 'location' argument 
        %   during datastore construction.
        %
        %   This property is used by the WRITEALL method (when 
        %   'FolderLayout' is set to 'duplicate') to define the folder
        %   structure generated in the output location.
        %
        %   The Folders property is populated differently depending on the
        %   values in the location input to the datastore:
        %     - Folder names: all folder names in the location input are
        %         directly added to the Folders property.
        %     - File names: the parent folders of all input filenames are
        %         added to the Folders property.
        %     - Wildcard file and folder names: wildcard strings passed to
        %         the datastore constructor are matched to filenames on
        %         disk. The parent folders of these filenames are then
        %         added to the Folders property.
        %
        %   The Folders property is read-only. It cannot be directly 
        %   modified without re-constructing the datastore.
        %
        %   The Folders property can be indirectly modified by changing
        %   the Files property or by calling the datastore partition method.
        %   During modification, any folder names that do not contain files
        %   listed in the datastore are removed from the Folders property.
        %
        %   See also matlab.io.datastore.TabularTextDatastore.writeall
        Folders(:, 1) cell {mustBeCellstr} = cell.empty(0, 1);
    end

    methods (Access = protected)
        %populateFoldersFromLocation is a convenience function for
        %   populating the Folders property from the location input to
        %   datastores.
        %
        %   The location input must be either:
        %     - A character vector listing a valid folder, file, or
        %       wildcard name.
        %     - A string array or cell array of character vectors 
        %       containing valid folder, file, or wildcard names.
        %     - A matlab.io.datastore.DsFileSet object.
        %
        %   See also: matlab.io.datastore.FoldersPropertyProvider
        populateFoldersFromLocation(ds, location);
    end

    properties (Access = protected)
        %RecalculateFolders   is a flag that controls whether the values in 
        %   the Folders property are recalculated on the next get.Folders.
        %   This provides a deferred mechanism of modifying the Folders
        %   property that is useful during partition and set/Files.
        %
        %   See also matlab.io.datastore.FoldersPropertyProvider.Folders
        RecalculateFolders(1, 1) logical = false;

        ExcludeFromEqualComparison(1, :) string = "RecalculateFolders";
    end

    % For internal use only.
    methods (Access = {?matlab.io.datastore.FoldersPropertyProvider, ...
                       ?matlab.io.datastore.FileBasedDatastore})

        %populateFoldersFromResolvedPaths is an internal function for
        %   populating the Folders property from the location input and a
        %   list of resolved files and folders.
        %
        %   The location input must be either:
        %     - A character vector listing a valid folder, file, or
        %       wildcard name.
        %     - A string array or cell array of character vectors
        %       containing valid folder, file, or wildcard names.
        %     - A matlab.io.datastore.DsFileSet object.
        %
        %   If a list of resolved folders or resolved files is already
        %   available, the second and third inputs can be provided as
        %   input to this method to optimize the Folders calculation.
        %
        %   resolvedSubfolders and resolvedFilenames must both be
        %   string arrays or cell arrays of character vectors.
        %
        %   See also: matlab.io.datastore.mixin.property.FoldersProperty
        populateFoldersFromResolvedPaths(ds, location, resolvedSubfolders, ...
            resolvedFilenames);

        %getFilesForFoldersRecalculation lists the files that should be
        %   used for calculating the folders property.
        %
        %   The returned list of files must be a fully-qualified
        %   resolved list of valid filenames on disk.
        files = getFilesForFoldersRecalculation(ds);

        %partitionFoldersProperty   a helper method that slices the folders
        %   property using the new indices provided in the partitionStrategy
        %   and partitionIndex.
        %
        %   If partitionStrategy is numeric and equal to partitionIndex,
        %   with a value of 1 then a trivial partition is assumed. In this case the
        %   Folders property is not recalculated, it is just copied.
        partitionFoldersProperty(ds, partitionStrategy, partitionIndex);
        
        %updateFoldersProperty   a helper method for updating the folders
        %   property whenever new files are added on the datastore.
        %
        %   For the initial datastore writeall release, this will clear the
        %   Folders property.
        updateFoldersProperty(ds);
    end

    methods
        function folders = get.Folders(ds)
            import matlab.io.datastore.internal.folders.removeFoldersWithoutFiles;
            
            % Recompute the Folders property when the datastore has
            % requested it.
            % This currently only happens for some built-in datastores
            % after the partition method is called.
            if ds.RecalculateFolders
                files = ds.getFilesForFoldersRecalculation();
                ds.Folders = removeFoldersWithoutFiles(ds.Folders, files);

                % Folders have been recomputed, set the flag back to false
                % to avoid another recalculation on the next get.Folders.
                ds.RecalculateFolders = false;
            end
            
            folders = ds.Folders;
        end
    end

    methods (Hidden)
        %isequaln   isequaln is overloaded for FoldersPropertyProvider
        %   objects in order to avoid spurious results due to internal
        %   changes from hidden properties like RecalculateFolders.
        tf = isequaln(ds1, ds2, varargin);
    end

    methods(Static, Hidden)
        %generateFoldersDisplayString    utility for generating a
        %   display string for the Folders property that can be re-used
        %   in subclasses.
        str = generateFoldersDisplayString(folders, initialIndent)
    end
end

function files = mustBeCellstr(files)
% mustBeCellstr validates that a cellstr or cellstr-convertible value
% was provided as input for this property.
%
% Adding this manually since it doesn't look like we have an existing
% convenience function for cellstr property validation.

    % Error if a cellstr was not provided as input.
    if ~iscellstr(files)
        msgid = "MATLAB:io:datastore:write:write:IncorrectFoldersPropertyType";
        error(message(msgid));
    end
end
