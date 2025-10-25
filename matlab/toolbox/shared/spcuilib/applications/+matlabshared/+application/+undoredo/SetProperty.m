classdef SetProperty < matlabshared.application.undoredo.Edit
    %SetProperty edit object to set property values
    
    %   Copyright 2017 The MathWorks, Inc.
    properties (SetAccess = protected)
        Object
        Property
        NewValue
        OldValue
    end
    
    methods
        function this = SetProperty(obj, name, value, oldValue)
            this.Object   = obj;
            this.Property = name;
            if iscell(name)
                %"numel(Property)" returns the number of characters
                cellDim = numel(name);
            else
                cellDim = 1;
            end
            NValue = cell(numel(obj), cellDim);
            OValue = cell(numel(obj), cellDim);            
            
            if isempty(value) || size(value,1) > numel(obj)
                for i=1:numel(obj)
                    for j=1:cellDim
                        NValue{i,j} = value;
                        if nargin < 4
                            OValue{i,j} = obj(i).(name);
                        else
                            OValue{i,j} = oldValue;
                        end
                    end
                end                
            elseif ~iscell(value)
                for i=1:numel(obj)
                    for j=1:cellDim
                        NValue{i,j} = value(i,:);
                        if nargin < 4
                            OValue{i,j} = obj(i).(name);
                        else
                            OValue{i,j} = oldValue(i,:);
                        end
                    end
                end                
            else
                if (cellDim > 1)
                    for i=1:numel(obj)
                        for j=1:cellDim
                            NValue{i,j} = value{i,j};
                        end
                    end
                    
                    if nargin < 4
                        for i=1:numel(obj)
                            for j=1:cellDim
                                OValue{i,j} = obj(i).(name);
                            end
                        end
                    else
                        for i=1:numel(obj)
                            for j=1:cellDim
                                OValue{i,j} = oldValue{i,j};
                            end
                        end
                    end
                else
                    NValue = value;
                    OValue = obj.(name);
                end
            end
            this.NewValue = NValue;
            this.OldValue = OValue;
        end
        
        function execute(this)
            obj = this.Object;
            if (numel(obj) == numel(this.NewValue))
                for i=1:numel(obj)
                    obj(i).(this.Property) = this.NewValue{i};
                end
            else
                obj.(this.Property) = this.NewValue;
            end
        end
        
        function undo(this)
            obj = this.Object;
            if (numel(obj) == numel(this.OldValue))
                for i=1:numel(this.Object)
                    obj(i).(this.Property) = this.OldValue{i};
                end
            else
                obj.(this.Property) = this.OldValue;
            end
        end
        
        function str = getDescription(this)
            str = getString(message('Spcuilib:application:SetPropertyDescription', this.Property));
        end
    end
end

% [EOF]
