classdef InspectorActionHelper < handle
    
    % This class provides a set of helper functions for the Inspector
    % Object browser and DataTipRows
    
    % Copyright 2018-2022 The MathWorks, Inc.
    
    methods (Static)
        
        % Event handler for client-side actions events
        function actionEventHandler(ed, metaDataHandler)
            arguments
                % Event data
                ed
                
                % The ObjetHierarchyMetaData class for the current object
                % browser display.
                metaDataHandler
            end

            switch ed.actionType
                case 'objectSelectionChanged'
                    try
                        matlab.graphics.internal.propertyinspector.BreadcrumbsHelper.actionEventHandler(ed , metaDataHandler);
                    catch
                        % Use the default event handler for
                        % objectSelectionChanged
                        internal.matlab.inspector.peer.InspectorObjectActionHelper.actionEventHandler(ed, metaDataHandler);
                    end
                    
                case {'propertyChanged', 'delete', 'dnd'}
                    matlab.graphics.internal.propertyinspector.BreadcrumbsHelper.actionEventHandler(ed);
                    
                case {'updateDataTipRow', 'deleteDataTipRow'}
                    matlab.graphics.datatip.internal.DataTipRowHelper.actionEventHandler(ed);

                case 'refreshDisplay'
                    mgr = internal.matlab.inspector.peer.InspectorFactory.createInspector('default', ed.channel);
                    mgr.reinspectCurrentObject(true);
            end
        end
    end
end