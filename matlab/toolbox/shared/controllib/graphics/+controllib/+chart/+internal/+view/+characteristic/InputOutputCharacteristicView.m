classdef InputOutputCharacteristicView < controllib.chart.internal.view.characteristic.BaseCharacteristicView
    % Base class for characteristic markers
    
    % Copyright 2021 The MathWorks, Inc.

    %% Properties
    properties (Dependent,SetAccess=private)
        ColumnNames
        RowNames
    end

    %% Constructor
    methods
        function this = InputOutputCharacteristicView(responseView,data)
            this@controllib.chart.internal.view.characteristic.BaseCharacteristicView(responseView,data);
        end
    end

    %% Get/Set
    methods
        % OutputNames
        function ColumnNames = get.ColumnNames(this)
            ColumnNames = this.ResponseView.ColumnNames;
        end
        % OutputNames
        function RowNames = get.RowNames(this)
            RowNames = this.ResponseView.RowNames;
        end
    end

    %% Public methods
    methods
        function setVisible(this,visible,optionalInputs)
            arguments
                this
                visible matlab.lang.OnOffSwitchState = this.Visible
                optionalInputs.InputVisible logical = true(1,this.Response.NColumns)
                optionalInputs.OutputVisible logical = true(this.Response.NRows,1)
                optionalInputs.ArrayVisible logical = true(1,this.Response.NResponses)
            end

            % Set visibility
            for kr = 1:this.Response.NRows
                for kc = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        visibleFlag = visible & optionalInputs.ArrayVisible(ka) & ...
                            optionalInputs.OutputVisible(kr) & optionalInputs.InputVisible(kc);
                        if ~isempty(this.Response.NominalIndex) && ka ~= this.Response.NominalIndex
                            visibleFlag = false;
                        end
                        cMarkers = getMarkerObjects(this,kr,kc,ka);
                        for ii = 1:numel(cMarkers{1})
                            cMarkers{1}(ii).Visible = visibleFlag;
                        end
                        rObjects = getResponseObjects(this,kr,kc,ka);
                        for ii = 1:numel(rObjects{1})
                            rObjects{1}(ii).Visible = visibleFlag;
                        end
                        sObjects = getSupportingObjects(this,kr,kc,ka);
                        for ii = 1:numel(sObjects{1})
                            sObjects{1}(ii).Visible = visibleFlag;
                        end
                    end
                end
            end
            this.Visible = visible;
        end

        function updateIODataTipRow(this)
            % Update response data tips
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    ioRow = getIODataTipRow(this,ki,ko);
                    if isempty(ioRow)
                        continue;
                    end
                    for ka = 1:this.Response.NResponses
                        markerObjects = getMarkerObjects(this,ko,ki,ka);
                        for k = 1:numel(markerObjects{1})
                            if isprop(markerObjects{1}(k),'DataTipTemplate')
                                idx = find(contains({markerObjects{1}(k).DataTipTemplate.DataTipRows.Label},...
                                    getString(message('Controllib:plots:strIO'))),1);
                                if ~isempty(idx)
                                    markerObjects{1}(k).DataTipTemplate.DataTipRows(idx) = ioRow;
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateDataTips(this,ko,ki,ka)
            % Create data tip for all lines
            % Name Data Tip Row
            nameDataTipRow = getNameDataTipRow(this,ka);
            % I/O row
            ioDataTipRow = getIODataTipRow(this,ki,ko);
            % Custom Data Tip Row
            customDataTipRows = getCustomDataTipRows(this,ko,ki,ka);

            % Call subclass implementation to create data
            % tips
            updateDataTips_(this,ko,ki,ka,...
                nameDataTipRow,ioDataTipRow,customDataTipRows);
        end

        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows) %#ok<INUSD>

        end

        function ioRow = getIODataTipRow(this,columnIdx,rowIdx)
            arguments
                this
                columnIdx
                rowIdx
            end
            if (this.Response.NColumns > 1 || this.Response.NRows > 1) && ...
                    length(this.ResponseView.ColumnNames) >= columnIdx && length(this.ResponseView.RowNames) >= rowIdx
                ioLabel = getString(message('Controllib:plots:InputToOutput',this.ResponseView.ColumnNames(columnIdx),...
                    this.ResponseView.RowNames(rowIdx)));
                ioRow = dataTipTextRow(getString(message('Controllib:plots:strIO')),...
                    {ioLabel});
            else
                ioRow = matlab.graphics.datatip.DataTipTextRow.empty;
            end
        end
    end
end