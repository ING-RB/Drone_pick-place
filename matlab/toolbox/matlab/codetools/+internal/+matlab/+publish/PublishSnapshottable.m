classdef PublishSnapshottable < internal.matlab.publish.PublishExtension
%

% Copyright 2020-2023 The MathWorks, Inc.

    properties
        eventsCollector = [];
    end
    
    methods
        
        function obj = PublishSnapshottable(options)
            obj = obj@internal.matlab.publish.PublishExtension(options);            
            obj.eventsCollector = matlab.internal.structuredoutput.EventsCollector('figure');
        end
        
        function enteringCell(~,~)
        end
        
        function newFiles = leavingCell(obj,~)
            
            newFiles = cell(0,1);
            
            exampleEvents = obj.eventsCollector.Events;
            
            % Clear events collector at the end of the section.
            cleanupObj.events = onCleanup(@() obj.eventsCollector.clear);
            cleanupObj.structuredFigures = onCleanup(@() builtin('_StructuredFiguresResetAll'));
            
            if isempty(exampleEvents)
                % No events to process
                return;
            end

            % Filter the events
            eventMap = containers.Map;
            uuidsArray = strings(0,1);
            for i = numel(exampleEvents):-1:1
                % Use reverse order to get last event for each payload, 
                % ignoring earlier events for same payload
                exampleEvent = exampleEvents(i);
                if isa(exampleEvent.payload, 'matlab.internal.structuredoutput.Snapshottable')
                    uuid = exampleEvent.payload.getVisualOutputUid();                     
                    if ~isKey(eventMap, uuid) 
                        eventMap(uuid) = exampleEvent.payload;
                        uuidsArray(end+1,1) = uuid; %#ok<AGROW>
                    end    
                end
            end
           
            N = numel(uuidsArray);            
            if N == 0
                % No Snapshottable payloads
                return;
            end
            
            % Reverse order, so earliest kept event/payload is first
            uuidsArray = flipud(uuidsArray);
            
            % Get payload image data
            for i = 1:N
                payload = eventMap(uuidsArray(i));
                imageData = payload.getImageDataForSnapshot();
                if ~isempty(imageData)
                    newFiles{end+1,1} = obj.snapFigure(imageData,...
                        obj.options.filenameGenerator(), obj.options); %#ok<AGROW>
                end
            end

        end
    end
    
    methods(Static)

       function imgFilename = snapFigure(cdata, imgNoExt, opts)                        
            % Nail down the image format.
            if isempty(opts.imageFormat)
                imageFormat = internal.matlab.publish.getDefaultImageFormat(opts.format, 'imwrite');
            else
                imageFormat = opts.imageFormat;
            end
            
            % Nail down the image filename.
            imgFilename = internal.matlab.publish.getPrintOutputFilename(imgNoExt, imageFormat);

            myFrame.cdata = cdata;
            myFrame.colormap = [];

            % Debugging information
            comment = '';

            % Finally, write out the image file. 
            internal.matlab.publish.writeImage(imgFilename, imageFormat, myFrame, opts.maxHeight, opts.maxWidth, comment);
        end
    end
end


