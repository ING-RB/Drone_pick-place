classdef SimulationFidelitySection < matlab.ui.internal.toolstrip.Section
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties
        Fidelity = 'cuboid';
    end
    
    properties (SetAccess = protected, Hidden)
        hItems;
    end
    
    events
        FidelityChanged
    end
    
    methods
        function this = SimulationFidelitySection(varargin)
            this@matlab.ui.internal.toolstrip.Section(getString(message('Spcuilib:application:FidelitySectionTitle')));
            this.Tag = 'simulationFidelity';
            import matlab.ui.internal.toolstrip.*
            
            simfid = DropDownButton(getString(message('Spcuilib:application:FidelityButtonText')), varargin{:});
            pop = PopupList;
            pop.Tag = 'SimulationFidelity';
            simfid.Popup = pop;
            
            cuboid  = ListItemWithCheckBox(getString(message('Spcuilib:application:CuboidItemText')));
            cuboid.Tag = 'cuboid';
            cuboid.ValueChangedFcn = @(~, ~) valueChanged(this, 'cuboid');
            lowPoly = ListItemWithCheckBox(getString(message('Spcuilib:application:LowPolygonItemText')));
            lowPoly.Tag = 'lowPoly';
            lowPoly.ValueChangedFcn = @(~, ~) valueChanged(this, 'lowPoly');
            gaming  = ListItemWithCheckBox(getString(message('Spcuilib:application:GamingEngingItemText')));
            gaming.Tag = 'gaming';
            gaming.ValueChangedFcn = @(~, ~) valueChanged(this, 'gaming');
            
            cuboid.ShowDescription  = false;
            lowPoly.ShowDescription = false;
            gaming.ShowDescription  = false;
            
            add(pop, cuboid);
            add(pop, lowPoly);
            add(pop, gaming);
            
            this.hItems = [cuboid lowPoly gaming];
            
            add(addColumn(this), simfid);
            
            updateItemsValue(this);
        end
        
        function set.Fidelity(this, newFidelity)
            this.Fidelity = newFidelity;
            updateItemsValue(this);
            notify(this, 'FidelityChanged');
        end
    end
    
    methods (Hidden)
        function valueChanged(this, newValue)
            this.Fidelity = newValue;
        end
    end
    
    methods (Access = protected)
        function updateItemsValue(this)
            matlabshared.application.updateDropDownChecked(this.hItems, this.Fidelity);
        end
    end
end

% [EOF]
