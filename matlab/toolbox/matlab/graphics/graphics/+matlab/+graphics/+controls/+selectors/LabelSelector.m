classdef LabelSelector < matlab.graphics.controls.selectors.BaseSelector
    % LABELSELECTOR Subclass of BaseSelector that handles logic for all
    % text objects that require selection from the toolstrip (e.g. Title,
    % SubTitle, XLabel, YLabel, ZLabel)
    
    % Copyright 2021-2024 The MathWorks, Inc.    
    properties(Access=protected)               
        % Cache the Label Value to put it in the undo stack
        CacheLabelValue;
        
        % Listener for when Editing has changed
        EditingListener;
    end

    methods
        function obj = LabelSelector(ax)
            obj@matlab.graphics.controls.selectors.BaseSelector(ax);                                                                                                                  
        end
        
        function delete(obj)
            delete(obj.EditingListener);
            
            obj.delete@matlab.graphics.controls.selectors.BaseSelector();
        end
    end       
    
    % Protected methods inherited from BaseSelector
    methods(Access=protected)
        
        function result = getSelectionObject(obj)     
            % For Label objects (title, subtitle, Xlabel, Ylabel, Zlabel)
            % using the MetaDataService will always return the correct text
            % object to operate on
            service = matlab.plottools.service.MetadataService.getInstance();
            adapter = service.getMetaDataAccessor(obj.Target);
            result = adapter.get(obj.FeatureName);
        end      

        function result = getDefaultString(~)
            % Override in the subclass
            result = '';
        end
             
        function result = isSupported(obj)
            result = obj.isSupported@matlab.graphics.controls.selectors.BaseSelector();

            textObj = obj.getSelectionObject();
            
            result = result && ~isempty(textObj) && isa(textObj, 'matlab.graphics.primitive.Text');
        end         
        
        function setInputState(obj)
            
            textObj = obj.getSelectionObject();
            
            if ~isempty(textObj)            
                if isempty(textObj.String)
                    obj.Control.String = obj.getDefaultString();
                else
                    obj.Control.String = textObj.String;
                end                     
            else
                % If the text object is empty, this Label is not supported
                % so use an empty string
                obj.Control.String = '';
            end
            
            obj.setInputState@matlab.graphics.controls.selectors.BaseSelector();   
        end           
                
        function info = getUndoInfo(obj)
            textObj = obj.getSelectionObject();           
            
            currentValue = textObj.String;
            oldValue = obj.CacheLabelValue;
            
            info.Name = 'textEdit';
            info.Object = textObj;
            info.Fcn = @(label,~) set(label, 'String', currentValue);
            info.InvFcn = @(label,~) set(label, 'String', oldValue);            
        end        
        
        function clickedCallback(obj, ~)
            textObj = obj.getSelectionObject();
            
            obj.CacheLabelValue = textObj.String;
                
            textObj.Editing = 'on';            
            
            obj.EditingListener = event.proplistener(textObj, textObj.findprop('Editing'),...
                'PostSet', @(~,~)obj.editingCallback());
            
            obj.Control.Visible = 'off';
        end     
        
        function editingCallback(obj)
            textObj = obj.getSelectionObject();
            
            if strcmpi(textObj.Editing, 'off')
                obj.registerUndo();
                obj.generateCode();               
            end               
        end
        
        function dismissedCallback(obj, evt, mouseData)
            textObj = obj.getSelectionObject();
            if obj.isSupported() && strcmpi(textObj.Editing, 'off')
                obj.dismissedCallback@matlab.graphics.controls.selectors.BaseSelector(evt, mouseData);
            end                    
        end             
    end    
end

