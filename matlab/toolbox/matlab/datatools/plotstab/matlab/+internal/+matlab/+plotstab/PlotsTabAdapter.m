classdef PlotsTabAdapter < handle
    %PLOTSTABADAPTER Summary of this class goes here
    
    % Copyright 2019-2023 The MathWorks, Inc.
    
    methods(Static = true)
        function obj = getInstance()
        persistent adapterInstance;
        mlock;
        if isempty(adapterInstance)
            adapterInstance = internal.matlab.plotstab.PlotsTabAdapter;
        end
        
        obj = adapterInstance;
        end
    end
    
    properties(Access=protected)
        PlotsMap
    end

    events
        PlotsMapBuilt
    end
    
    methods(Access=private)
        function obj = PlotsTabAdapter()     
            obj.PlotsMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
        
        % Build the plots map from the new RegistrationService. We'll get our 
        % Messages about this from the client
        function obj = buildPlotsMap(obj, plots)
            if ~isempty(plots)

                for k = 1:length(plots)

                    item = plots{k};

                    s = obj.buildPlotStruct(item);

                    if isfield(s, 'id')
                        obj.PlotsMap(s.id) = s;
                    end
                end                
            end
            obj.notify('PlotsMapBuilt');
        end   
        
        function s = buildPlotStruct(~, item)
            s = struct();

            if ~isfield(item, 'tag') || ~isfield(item, 'function')
                return;
            end
            
            s.id = item.tag;

            if isfield(item, 'visibility')
                s.selectionCode = item.visibility;
            else
                s.selectionCode = [];
            end

            s.isGUI = isfield(item, 'gui') && strcmp(item.gui, 'yes');

            s.hasCustomFcn = isfield(item, 'action') && ~isempty(item.action);

            if s.hasCustomFcn
                s.customExeFcn = item.action;
            end
            
            s.evalFcn = item.function;            
        end
        
        function appendToMap(obj, plots)
            if ~isempty(plots)
                for k = 1:length(plots)

                    item = plots{k};

                    s = obj.buildPlotStruct(item);

                    if isfield(s, 'id')
                        obj.PlotsMap(s.id) = s;
                    end
                end
            end        
        end
        
        function removeFromMap(obj, plots)
            if ~isempty(plots)
                for k = 1:length(plots)

                    item = plots{k};

                    s = obj.buildPlotStruct(item);

                    remove(obj.PlotsMap, s.id);
                end
            end          
        end
    end
    
    methods(Access = public)
        function map = getPlotsMap(obj)
            map = obj.PlotsMap;
        end
        
        function updatePlotsMap(obj, data, type)
            % If this is the first time upding, build the map
            if isempty(obj.PlotsMap) || strcmp(type, 'build')
                obj.buildPlotsMap(data);
            else
                if strcmp(type, 'add')
                    obj.appendToMap(data);
                else
                    obj.removeFromMap(data);
                end
            end
        end        
    end
end

