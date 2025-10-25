classdef ImportState < controllib.ui.internal.dialog.AbstractImportDialog
    %   Import State Dialog for Linear Simulation Tool
    
    %   Copyright 2020 The MathWorks, Inc.

    properties(GetAccess = public, SetAccess = private)
        InitialTable        
    end
    
    methods
        function this = ImportState(initialTable)
            arguments
                initialTable = []
            end
            this = this@controllib.ui.internal.dialog.AbstractImportDialog;
            this.AllowMultipleRowSelection = false;
            this.AllowColumnSorting = true;
            this.ShowHelpButton = false;
            this.AddTagsToWidgets = true;
            this.Name = 'ImportTimeDialog'; 
            this.Title = getString(message('Controllib:gui:strStateImport'));
            this.TableTitle = getString(message('Controllib:gui:lblImportInitialStateFromWorkspace'));
            this.DialogSize = [460 200];
            this.InitialTable = initialTable;
        end
    end
    
    methods(Access = protected)
        function tableData = getTableData(this)
            % Return the table to be displayed by AbstractImportDialog
            % Name,Type,Order,NumInputs,NumOutputs
            filteredData = getFilteredData(this);
            variableNames = {'Variable Name',...
                'Size',...
                'Bytes',...
                'Class'};
            if ~isempty(filteredData)
                this.localCreateVariables(filteredData);
                variableClass = cell(size(filteredData,1),1);
                variableSize = cell(size(filteredData,1),1);
                variableBytes = zeros(size(filteredData,1),1);
                for k = 1:size(filteredData,1)
                    w = whos(filteredData{k,1});
                    variableBytes(k) = w.bytes;
                    variableClass{k} = w.class;
                    variableSize{k} = [mat2str(w.size(1)),' x ',mat2str(w.size(2))];
                end
                tableData = table(filteredData(:,1),...
                    variableSize,variableBytes,variableClass,...
                    'VariableNames',variableNames);
            else
                tableData = table([],[],[],[],'VariableNames',variableNames);
            end
        end
        
        function callbackActionButton(this)
            % Get selected data from AbstractImportDialog helper method
            selectedData = getSelectedData(this);
            % Error dialog if selection is empty
            if isempty(selectedData)
                uiconfirm(getWidget(this),...
                    getString(message('Controllib:gui:errSelectVariableToImport')),...
                    getString(message('Controllib:gui:strLinearSimulationTool')),...
                    'Icon','error');
                return;
            else
                updateState(this.InitialTable,selectedData{:,2});
            end
        end
        
        function callbackHelpButton(this) %#ok<*MANU>
            
        end
    end
    
    methods(Hidden)
        function widgets = qeGetCustomWidgets(this)
            widgets.DialogName = this.Name;
            widgets.DialogTitle = this.Title;
            widgets.DialogTableTitle = this.TableTitle;
        end
    end
    
    methods(Access = private)
        function filteredData = getFilteredData(this)
            data = getData(this);
            if isempty(data)
                filteredData = data;
            else
                n = length(this.InitialTable.Data.InitialStates{this.InitialTable.SelectedSystem});
                isValidType = cellfun(@(x) isDataValid(x,n),data(:,2));
                filteredData = data(isValidType,:);
            end
        end
        function localCreateVariables(~,data)
            for k = 1:size(data,1)
                assignin('caller',data{k,1},data{k,2});
            end
        end
    end
end

function validFlag = isDataValid(x,n)
checkLength = (length(x) == n);
validFlag = isnumeric(x) && isvector(x) && isreal(x) && checkLength;
end
