classdef OutputCharacteristicView < controllib.chart.internal.view.characteristic.BaseCharacteristicView
    
    % Copyright 2021 The MathWorks, Inc.

    %% Properties
    properties (Dependent,SetAccess=private)
        OutputNames
    end

    %% Constructor
    methods
        function this = OutputCharacteristicView(responseView,data)
            this@controllib.chart.internal.view.characteristic.BaseCharacteristicView(responseView,data);
        end
    end

    %% Get/Set
    methods
        % OutputNames
        function OutputNames = get.OutputNames(this)
            OutputNames = this.ResponseView.OutputNames;
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
                for ka = 1:this.Response.NResponses
                    visibleFlag = visible & optionalInputs.ArrayVisible(ka) & ...
                        optionalInputs.OutputVisible(kr);
                    if ~isempty(this.Response.NominalIndex) && ka ~= this.Response.NominalIndex
                        visibleFlag = false;
                    end
                    cMarkers = getMarkerObjects(this,kr,1,ka);
                    for ii = 1:numel(cMarkers{1})
                        cMarkers{1}(ii).Visible = visibleFlag;
                    end
                    rObjects = getResponseObjects(this,kr,1,ka);
                    for ii = 1:numel(rObjects{1})
                        rObjects{1}(ii).Visible = visibleFlag;
                    end
                    sObjects = getSupportingObjects(this,kr,1,ka);
                    for ii = 1:numel(sObjects{1})
                        sObjects{1}(ii).Visible = visibleFlag;
                    end
                end
            end
            this.Visible = visible;
        end

        function updateOutputDataTipRow(this)
            % Update response data tips
            for ko = 1:this.Response.NRows
                outputRow = getOutputDataTipRow(this,ko);
                if isempty(outputRow)
                    continue;
                end
                for ka = 1:this.Response.NResponses
                    markerObjects = getMarkerObjects(this,ko,1,ka);
                    for k = 1:numel(markerObjects{1})
                        if isprop(markerObjects{1}(k),'DataTipTemplate')
                            idx = find(contains({markerObjects{1}(k).DataTipTemplate.DataTipRows.Label},...
                                getString(message('Controllib:plots:strOutput'))),1);
                            if ~isempty(idx)
                                markerObjects{1}(k).DataTipTemplate.DataTipRows(idx) = outputRow;
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
            outputDataTipRow = getOutputDataTipRow(this,ko);
            % Custom Data Tip Row
            customDataTipRows = getCustomDataTipRows(this,ko,ki,ka);

            % Call subclass implementation to create data
            % tips
            updateDataTips_(this,ko,ka,...
                nameDataTipRow,outputDataTipRow,customDataTipRows);
        end

        function updateDataTips_(this,ko,ka,nameDataTipRow,outputDataTipRow,customDataTipRows) %#ok<INUSD>

        end

        function ioRow = getOutputDataTipRow(this,outputIdx)
            arguments
                this
                outputIdx
            end
            if this.Response.NRows > 1 && length(this.OutputNames) >= outputIdx
                ioRow = dataTipTextRow(getString(message('Controllib:plots:strOutput')),@(x) string(this.OutputNames(outputIdx)));
            else
                ioRow = matlab.graphics.datatip.DataTipTextRow.empty;
            end
        end
    end
end