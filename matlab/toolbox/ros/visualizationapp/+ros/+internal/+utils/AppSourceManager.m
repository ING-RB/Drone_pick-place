classdef AppSourceManager < handle
    % ThreeDModel - Manages 3D visualizers and transforms messages.
    %
    % This internal class handles the management of 3D visualizers,
    % including adding, updating, and removing visualizers and their
    % associated sources. It utilizes a transformation tree and a
    % ModelHelper instance to transform messages to specified frames.

    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2024 The MathWorks, Inc.


    properties
        % Nested map to store visualizer data
        VisualizersMap
    end
    
    methods
        function obj = AppSourceManager()
            % Constructor to initialize the properties
            obj.VisualizersMap = containers.Map('KeyType', 'double', 'ValueType', 'any');
        end
        
        function addVisualizer(obj, visualizerID, frame_id)
            % Add a new visualizer with a specified frame ID
            if ~isKey(obj.VisualizersMap, visualizerID)
                obj.VisualizersMap(visualizerID) = struct('frame_id', frame_id, 'sources', containers.Map('KeyType', 'char', 'ValueType', 'any'));
            end
        end
        
        function removeVisualizer(obj, visualizerID)
            % Remove a visualizer by ID
            if isKey(obj.VisualizersMap, visualizerID)
                remove(obj.VisualizersMap, visualizerID);
            end
        end
        
        function updateFrameID(obj, visualizerID, newFrameID)
            % Update the frame ID of an existing visualizer
            if isKey(obj.VisualizersMap, visualizerID)
                vizData = obj.VisualizersMap(visualizerID);
                vizData.frame_id = newFrameID;
                obj.VisualizersMap(visualizerID) = vizData;
            end
        end
        
        function updateSource(obj, visualizerID, source, colorMode, color)
            % update source properties for a visualizer
            if isKey(obj.VisualizersMap, visualizerID)
                sourceMap = obj.VisualizersMap(visualizerID).sources;
                if isKey(sourceMap, source)
                    existingSource = sourceMap(source);
                    if ~isequal(existingSource.ColorMode, colorMode) || ~isequal(existingSource.Color, color)
                        sourceMap(source) = struct('ColorMode', colorMode, 'Color', color);
                    end
                end
            end
        end
        
        function addSource(obj, visualizerID, source)
            % add source to a visualizer
            if isKey(obj.VisualizersMap, visualizerID)
                sourceMap = obj.VisualizersMap(visualizerID).sources; 
                sourceMap(source) = struct('ColorMode', 'Default', 'Color', []);
            end
        end

        function removeSource(obj, visualizerID, source)
            % Remove a source from a visualizer
            if isKey(obj.VisualizersMap, visualizerID)
                sourceMap = obj.VisualizersMap(visualizerID).sources;
                if isKey(sourceMap, source)
                    remove(sourceMap, source);
                end
            end
        end
        
        function frame_id = getFrameID(obj, visualizerID)
            % Retrieve the frame ID of a visualizer
            frame_id = '';
            if isKey(obj.VisualizersMap, visualizerID)
                frame_id = obj.VisualizersMap(visualizerID).frame_id;
            end
        end
        
        function sourceData = getSource(obj, visualizerID, source)
            % Retrieve source data from a visualizer
            sourceData = [];
            if isKey(obj.VisualizersMap, visualizerID)
                sourceMap = obj.VisualizersMap(visualizerID).sources;
                if isKey(sourceMap, source)
                    sourceData = sourceMap(source);
                end
            end
        end

        function sources = getSources(obj, visualizerID)
            sources = [];
            if isKey(obj.VisualizersMap, visualizerID)
                sourcesMap = obj.VisualizersMap(visualizerID).sources;
                sources = keys(sourcesMap);
            end
        end

        function resetAllVisualizers(obj)
            % Reset all visualizers by clearing their sources
            % This function is used when user clicks on the refresh button
            % in the App.
            visualizerIDs = keys(obj.VisualizersMap);
            for i = 1:length(visualizerIDs)
                visualizerID = visualizerIDs{i};
                if isKey(obj.VisualizersMap, visualizerID)
                    sourcesMap = obj.VisualizersMap(visualizerID);
                    sourcesMap.sources = containers.Map('KeyType', 'char', 'ValueType', 'any');
                    obj.VisualizersMap(visualizerID) = sourcesMap;
                end
            end
        end

    end
end

% LocalWords:  DModel
