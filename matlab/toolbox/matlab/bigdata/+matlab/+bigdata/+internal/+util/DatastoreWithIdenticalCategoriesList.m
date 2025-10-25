classdef DatastoreWithIdenticalCategoriesList < handle
    %DATASTOREWITHIDENTICALCATEGORIESLIST Holds a list of datastores that
    %can guarantee that all partitions with categorical arrays have the
    %entire set of categories.

    %   Copyright 2023 The MathWorks, Inc.

    properties(Constant)
        % Datastores that guarantee identical categories.
        DatastoresWithIdenticalCategories = ["matlab.io.datastore.TallDatastore"];
    end

    methods (Static)
        function [allowed, restoreFcn] = addOrRemoveDatastore(dsClass, onOff)
            % Add/remove datastore from the list of datastores that
            % guarantee identical categories in all partitions.
            import matlab.bigdata.internal.util.DatastoreWithIdenticalCategoriesList;

            persistent ALLOWED
            if isempty(ALLOWED)
                ALLOWED = DatastoreWithIdenticalCategoriesList.DatastoresWithIdenticalCategories;
            end
            allowed = ALLOWED;
            restoreFcn = [];
            if nargin == 2
                if onOff == "on"
                    % Add new datastore class
                    ALLOWED = union(ALLOWED, dsClass);
                    assert(nargout == 2, "When adding a class, must capture restore function for cleanup.");
                    restoreFcn = @() DatastoreWithIdenticalCategoriesList.addOrRemoveDatastore(dsClass, "off");
                else
                    % Remove datastore class
                    ALLOWED = setdiff(ALLOWED, dsClass);
                end
            end
        end

        function tf = isGuaranteedIdenticalCategories(in)
            % Returns TRUE if the categorical arrays returned by this
            % datastore have identical categories in all partitions.
            import matlab.bigdata.internal.util.DatastoreWithIdenticalCategoriesList;

            clz = class(in);
            if clz == "matlab.io.datastore.internal.FrameworkDatastore"
                clz = class(in.Datastore);
            end
            tf = ismember(clz, DatastoreWithIdenticalCategoriesList.addOrRemoveDatastore());

            % 'TallDatastore' can only guarantee that it returns
            % categoricals with identical categories in all partitions if
            % all the files are stored in a single directory.
            if clz == "matlab.io.datastore.TallDatastore"
                paths = cellfun(@fileparts, in.Files, 'UniformOutput', false);
                tf = tf && isscalar(unique(paths));
            end
        end
    end
end