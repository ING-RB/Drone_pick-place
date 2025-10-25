classdef (Hidden) FigureManagerObserver < handle
    %FIGUREMANAGEROBSERVER - keeps a track of the number of figures snapshoted on the server
    
    properties
        Status 
        FiguresOnServer
        FigureMap;
        IncrementTimes;
        DecrementTimes;
        IsPublishingTest = false;
    end
    
    methods
        
        function obj = FigureManagerObserver
            obj.Status = false;
            obj.FiguresOnServer = 0;   
            if matlab.graphics.interaction.internal.isPublishingTest
                obj.configureForPublishing;
            end
        end
        
        function configureForPublishing(obj)
            % Capture logging information for use in publishing tests
            obj.IsPublishingTest = true;
            obj.FigureMap = containers.Map;
            obj.IncrementTimes = containers.Map;
            obj.DecrementTimes = containers.Map;
        end
        
        function increment(obj, eventData)        
            obj.FiguresOnServer = obj.FiguresOnServer + 1;
            % Reset the Status (just in case it got flipped. E.g. animated lines)
            obj.Status = false;
            
            % Capture the figure properties for this pending snapshot
            if obj.IsPublishingTest
                obj.FigureMap(eventData.FigureId) = get(eventData.Figure);
                obj.IncrementTimes(eventData.FigureId) = datestr(now);
            end
        end
        
        function decrement(obj, eventData)        
            obj.FiguresOnServer = obj.FiguresOnServer - 1;
            
            % Once the figure is snapshot-ed remove its properties from the
            % FigureMap and log the time
            if obj.IsPublishingTest
                if obj.FigureMap.isKey(eventData.FigureId)
                    remove(obj.FigureMap,eventData.FigureId);
                end
                obj.DecrementTimes(eventData.FigureId) = datestr(now);
            end
            
            if obj.FiguresOnServer == 0
                obj.Status = true;
            end
        end 
       
        
        function log(obj)
            % Display logged data for use in publishing tests
            if ~obj.IsPublishingTest
                return
            end
            
            % Report properties of unsnapshotted figures
            unsnapshotFigureIds = obj.FigureMap.keys;
            fprintf('\n');
            disp('Unsnapshotted Figure Properties')
            for k=1:length(obj.FigureMap)
                fprintf('FigureID:%s\n',unsnapshotFigureIds{k});
                disp(obj.FigureMap(unsnapshotFigureIds{k}));
            end
            
            % Report the timing of snapshot creation
            figureIds = obj.IncrementTimes.keys;
            if length(figureIds)>=1
                disp('Figure Output creation times:');       
                for k=1:length(obj.IncrementTimes)
                    fprintf('FigureID:%s:%s\n',figureIds{k},obj.IncrementTimes(figureIds{k}));
                end
            end
            figureIds = obj.DecrementTimes.keys;
            if length(figureIds)>=1
                disp('Figure Output dom node added times:');
                figureIds = obj.DecrementTimes.keys;
                for k=1:length(obj.DecrementTimes)
                    fprintf('FigureID:%s:%s\n',figureIds{k},obj.DecrementTimes(figureIds{k}));
                end
            end
        end
    end
    
end

