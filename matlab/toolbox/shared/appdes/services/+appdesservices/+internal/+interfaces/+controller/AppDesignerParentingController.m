classdef AppDesignerParentingController < ...
        appdesservices.internal.interfaces.controller.DesignTimeParentingController
    %

    % Copyright 2014-2015 The MathWorks, Inc.
    
    methods
        function obj = AppDesignerParentingController(varargin)
            
            % construct the DesignTimeParentingController with a factory
            obj = obj@appdesservices.internal.interfaces.controller.DesignTimeParentingController(varargin{:});
        end        
    end
    
    methods (Access=protected)
        
        function model = getModel(obj)
            % retrieve the model for this controller
            model = obj.Model;
        end
        
        function deleteChild(obj, model, objectToDelete)
            % delete the child object from the model         
            model.removeChild(objectToDelete, []);
            delete(objectToDelete);
        end        
    end
    
    methods(Access = {...
            ?appdesservices.internal.interfaces.controller.AbstractController,...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin,...
            ?matlab.ui.internal.DesignTimeGBTComponentController,...
            })
        function children = getAllChildren(obj, model)
            % Override the method in base class - DesignTimeParentingController
            % the default implementation for design-time component is to
            % use allchild() to get all child components regardless of
            % HandleVisibility, however App Designer models, like
            % AppDesignerModel, AppModel don't fall in such a situation,
            % calling allchild() on these App Designer models causing
            % errors because allchild() does validation checking
            children = model.Children;
        end
        
        function child = findChildByPeerNode(obj, peerNode)
            child = [];
            
            children = obj.getAllChildren(obj.getModel());
            
            if ~isempty(children)
                child = appdesservices.internal.interfaces.controller.DesignTimeParentingController.findChild(children, char(peerNode.getId()));
            end            
        end
    end
end


