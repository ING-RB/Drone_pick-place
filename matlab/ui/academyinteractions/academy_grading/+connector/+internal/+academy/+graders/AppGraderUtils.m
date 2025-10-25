classdef AppGraderUtils
    %APPGRADERUTILS is a collection of static utility functions that
    %grade MATLAB apps, such as comparing app state or other variables

    % Copyright 2020-2022 The MathWorks, Inc.

    properties (Constant)
        baseFolder    = fullfile(tempdir, '.training');
        testFolder    = fullfile(tempdir,'.training','tests');
        gradingFolder = fullfile(tempdir,'.training','grading');
    end

    methods(Static)
        % These method names are dynamically generated in MATLABAppTaskService
        % and are based on the appname.
        function out = gradeDeepNetworkDesigner(workDir, solutionFile)
            try
                % Use a helper function to extract the network object from a mat
                % file. This function will return a layergraph or a dlnetwork. An empty
                % layergraph is returned if no networks are found.
                fileName = fullfile(workDir, solutionFile);
                expected = connector.internal.academy.graders.AppGraderUtils.getNetworkLayerObject(fileName);

                % Get the network from DND. Depending on what type expected
                % is, try to retrieve the same type from DND
                if isa(expected, 'dlnetwork')
                    actual = deepapp.internal.sdk.getDLNetworkFromDND;
                else
                    actual = deepapp.internal.sdk.getNetworkFromDND;
                end

                out = connector.internal.academy.graders.AppGraderUtils.compareDeepNetworkDesignerNetworks(expected, actual);
            catch ex
                out = false;
            end
        end

        % These method names are dynamically generated in MATLABAppTaskService
        % and are based on the appname. Returns a handle to the classification learner app
        function out = gradeClassificationLearner(~, ~)
            out = mlearnapp.internal.adapterlayer.AppProxy('classification');
        end

        % These method names are dynamically generated in MATLABAppTaskService
        % and are based on the appname. Returns a handle to the appproxy that provides access to
        % regression learner app state
        function out = gradeRegressionLearner(~, ~)
            out = mlearnapp.internal.adapterlayer.AppProxy('regression');
        end
    end

    % Unit testable access methods.
    methods (Static=true)

        % Gets the network from the struct and returns a layer array or a dlnetwork.
        function out = getNetworkLayerObject(fileName)
            out = [];

            solnStruct = [];
            if exist(fileName, 'file') == 2
                solnStruct = load(fileName);
            end

            if ~isempty(solnStruct)
                propNames = fields(solnStruct);
                for i=1:numel(propNames)
                    val = solnStruct.(propNames{i});
                    if isa(val, 'dlnetwork')
                        out = val;
                    elseif isa(val, 'nnet.cnn.layer.Layer') || isa(val, 'DAGNetwork')
                        out = layerGraph(val);
                    elseif isa(val, 'SeriesNetwork')
                        out = layerGraph(val.Layers);
                    elseif isa(val, 'nnet.cnn.LayerGraph')
                        out = val;
                    end
                end     
            end
            % If we didnt find a network object in the struct. Return an empty layerGraph
            if isempty(out)
                out = layerGraph;
            end
        end

        % Expects the expected and actual values to be either Layer array or
        % Layer Graph. This indirection is here so that unit tests can call this function
        % without having to go through the gradeDeepNetworkDesigner function.
        function out = compareDeepNetworkDesignerNetworks(expected, actual)
            try
                % Use the isequal function for the networks to compare the
                % expected and actual networks.
                out = isequal(expected, actual);
            catch
                out = false;
            end
        end
    end
end