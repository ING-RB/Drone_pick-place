classdef (Hidden, Abstract) SubsasgnableFileSetLabels < ...
        matlab.io.datastore.internal.util.SubsasgnableFileSet
%SUBSASGNABLEFILESETLABELS Abstraction layer to set Files on FileSet and Labels.
%   Settting Files on a FileSet is not allowed but there are some methods,
%   that can accomplish this with nuance. When datastores have Labels property
%   the assignment has to go hand in hand. One example is that Labels need to
%   always have one-to-one mapping with Files.
%
%   See also matlab.io.datastore.ImageDatastore.

%   Copyright 2018-2021 The MathWorks, Inc.

    properties (Abstract)
        %LABELS
        % A set of labels with a one-to-one mapping of the Files property.
        Labels;
    end

    methods (Access = protected)
        function [diffIndexes, currIndexes] = setFilesOnFileSet(ds, files)
            c = onCleanup(@() initializeSubsAsgnIndexes(ds));
            [diffIndexes, currIndexes] = setFilesOnFileSet@matlab.io.datastore.internal.util.SubsasgnableFileSet(ds, files);
            resolveLabelsIndexes(ds);
        end

        function resolveLabelsIndexes(ds)
            % If the filenames are modified, Labels are not changed
            % If any additional files are added, we add default values
            % for the respective Labels.
            %
            %    Labels Type   Default
            %    -----------   -------
            %    cellstr        ''
            %    numerical      0
            %    logical        false
            %    categorical    <undefined>
            %
            if isempty(ds.Labels)
                return;
            end
            if ds.NumFiles == 0 || ds.FilesAssigned
                ds.Labels = {};
                return;
            end
            if ~isempty(ds.EmptyIndexes)
                ds.Labels(ds.EmptyIndexes) = [];
            end
            if ~isempty(ds.AddedIndexes)
                nv = numel(ds.AddedIndexes);
                addLabels = iGetDefaultLabels(ds.Labels, nv);
                ds.Labels(ds.AddedIndexes) = addLabels;
            end
        end

        function initWithIndices(ds, indexes, varargin)
            %INITWITHINDICES Initialize datastore with specific file indexes.
            %   This can be used to initialize the datastore with ReadFcn and files/fileSizes
            %   found previously or already existing in the splitter information.

            initWithIndices@matlab.io.datastore.internal.util.SubsasgnableFileSet(ds, indexes, varargin{:});

            % Set labels after files are set, since the labels setter
            % checks for number of files to be equal.
            if ~isempty(ds.Labels)
                % Do not change the label categories, i.e,
                % the original categories must remain the same for categorical Labels.
                ds.Labels = ds.Labels(indexes,:);
            end
        end

        function label = getLabelUsingIndex(ds, idx)
            if isempty(ds.Labels)
                label = {};
                return;
            end
            
            % If dsLabels is a cell array and only one Label is requested,
            % use content indexing to return a char array
            if iscell(ds.Labels) && numel(idx) == 1
                label = ds.Labels{idx};
            else
                label = ds.Labels(idx);
            end
        end

    end % methods

end % classdef

function labels = iGetDefaultLabels(sampleLabels, numLabels)
    switch class(sampleLabels)
        case 'cell'
            labels = repmat({''}, numLabels, 1);
        case 'logical'
            labels = false(numLabels,1);
        case 'categorical'
            labels = categorical(nan(numLabels,1));
        otherwise
            % It has to be numerical at this point, since
            % labels can only be numerical, logical, cellstr or
            % categorical.
            labels = zeros(numLabels, 1,'like',sampleLabels);
    end
end
