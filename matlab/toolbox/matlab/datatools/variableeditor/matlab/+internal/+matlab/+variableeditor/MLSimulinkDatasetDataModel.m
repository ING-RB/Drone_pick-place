classdef MLSimulinkDatasetDataModel < internal.matlab.variableeditor.MLObjectDataModel
    % MLSIMULINKDATASETDATAMODEL
    % Maintains cache to store information of the entire Dataset Object.
    % Cache is accessed by SimulinkDatasetViewModel to populate the
    % FieldColumns.

    % Copyright 2021 The MathWorks, Inc.

    %% Cache
    properties (Access = 'private')
        dsElementNames
        dsBlockPaths
        dsClasses
        dsCellData
        dsVirtualVals
        dsAccessVals
    end

    methods(Access='public')
        %% Constructor
        function this = MLSimulinkDatasetDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLObjectDataModel(name, workspace);
        end

        %% Handle Data Change
        function data = updateData(this, varargin)
            this.Data = varargin{1};
            this.setCache(this.Data);
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            this.notify('DataChange', eventdata);
            data = varargin{1};
        end

        %% Set Cache
        function setCache(this, data)
            if isempty(data)
                this.clearCache();
                return;
            end

            % Retrieve Storage Object for faster performance since it
            % contains all the data in form of Cell Array.
            storage = getStorage(data);
            elements = utGetElements(storage);
            nelems = numElements(storage);
            this.dsCellData = cell(nelems,1);
            this.dsElementNames = cell(nelems, 1);
            this.dsBlockPaths = cell(nelems, 1);
            this.dsClasses = cell(nelems, 1);

            for idx = 1:nelems
                elm = elements{idx};

                if isa(elm, 'Simulink.SimulationData.TransparentElement')
                    this.dsCellData{idx} = elm.Values;
                else
                    this.dsCellData{idx} = elm;
                end

                if isa(elm, 'sltest.Assessment')
                    this.dsElementNames{idx} = elm.getDisplayStr();
                else
                    this.dsElementNames{idx} = elm.Name;
                end

                if isa(elm,  'Simulink.SimulationData.BlockData')
                    blockPathCellArray = elm.BlockPath.convertToCell();
                    if isempty(blockPathCellArray)
                        this.dsBlockPaths{idx} = '';
                    elseif numel(blockPathCellArray) > 1
                        % Call strjoin only when there are more than 1 BlockPath
                        % elements to reduce unnecessary slowdown.
                        this.dsBlockPaths{idx} = strjoin(blockPathCellArray, '|');
                    else
                        this.dsBlockPaths{idx} = blockPathCellArray{1};
                    end
                else
                    this.dsBlockPaths{idx} = '';
                end

                this.dsClasses{idx} = class(this.dsCellData{idx});
            end
            this.dsVirtualVals = false(nelems, 1);
            this.dsAccessVals = repmat({'public'}, nelems, 1);
        end

        %% Clear Cache
        function clearCache(this)
            this.dsCellData = {};
            this.dsElementNames = {};
            this.dsBlockPaths = {};
            this.dsClasses = {};
            this.dsVirtualVals = {};
            this.dsAccessVals = {};
        end

        %% Getters/Setters
        function elementNames = getDSElementNames(this)
            elementNames = this.dsElementNames;
        end

        function blockPaths = getDSBlockPaths(this)
            blockPaths = this.dsBlockPaths;
        end

        function classes = getDSClasses(this)
            classes = this.dsClasses;
        end

        function cellData = getDSCellData(this)
            cellData = this.dsCellData;
        end

        function virtualVals = getDSVirtualVals(this)
            virtualVals = this.dsVirtualVals;
        end

        function accessVals = getDSAccessVals(this)
            accessVals = this.dsAccessVals;
        end
    end

    methods (Access = 'protected')
        % Overrided Method
        % Super class compares new Data to current Data using "isequal"
        % to determine whether the cache needs update but comparing
        % two Dataset Objects is very expensive using "isequal" or
        % any other means, so whenever "this.Data = newData" is executed,
        % always perform the assignment without checking for equality.
        function isUpdateNeeded = isDataEqual(~, ~)
            isUpdateNeeded = true;
        end
    end
end
