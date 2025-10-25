classdef ConfigureMetadata < handle
    % MetadataApp This class acts as controller for the MetadataApp
    % It instantiates and co-ordinates between Model, ViewModels and the UI
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties (Access = private)
        Model                    appdesigner.internal.usercomponent.metadata.Model
        MetadataUIViewModel      appdesigner.internal.usercomponent.metadata.MetadataUIViewModel
        UpdateModelEventListener % reference to event listener for UpdateModelEvent
        CleanUpAppEventListener  % reference to event listener for CleanUpEvent
    end
    
    methods(Access = public)
        function obj = ConfigureMetadata(userComponentFilePath)
            % This funtion is the entry-point for the ConfigureMetadata app
            import appdesigner.internal.usercomponent.metadata.Constants
                     
            % create and store Model from the provided userComponentFilePath
            obj.Model = appdesigner.internal.usercomponent.metadata.Model(userComponentFilePath);
            
            % create MetadataUIViewModel
            payload = struct();
            payload.Metadata = obj.Model.getComponentMetadata();
            payload.Categories = obj.Model.getCategories();
            payload.Directory = obj.Model.getDirectory();
            payload.ModelValidity = obj.Model.getModelValidity();
            payload.FilePath = userComponentFilePath;
         
            obj.MetadataUIViewModel = appdesigner.internal.usercomponent.metadata.MetadataUIViewModel(payload);
            
            % add event-listeners to the viewmodel
            obj.UpdateModelEventListener = addlistener(obj.MetadataUIViewModel, Constants.UpdateModelEvent, @obj.updateModel);
            obj.CleanUpAppEventListener = addlistener(obj.MetadataUIViewModel, Constants.CleanUpAppEvent, @obj.cleanUpApp);
            
            % open MetadataUI
            appdesigner.internal.usercomponent.metadata.MetadataUI(obj.MetadataUIViewModel);
        end
    end  
    
   methods(Access = private)
        
        function updateModel(obj, ~, eventData)
            % updateModel: Event listener for UpdateModelEvent
            % the UpdateModelEvent is fired when the component author
            % registers, updates or de-registers a component
            import appdesigner.internal.usercomponent.metadata.Constants
            
            metadata = eventData.Metadata;
            
            % call appropriate method on Model based on the UpadateType
            try
                switch eventData.UpdateType
                    case Constants.Register
                        obj.Model.registerComponent(metadata);
                    case Constants.Update
                        obj.Model.updateComponent(metadata);
                end
                obj.MetadataUIViewModel.handleRegistrationSuccess();
            catch me               
                obj.MetadataUIViewModel.handleRegistrationError(me);
            end
        end
        
        function cleanUpApp(obj, ~, ~)
            % cleanMetadataApp: this funtion deletes all listener and
            % properties of the MetadataApp
            
            delete(obj.UpdateModelEventListener);
            delete(obj.CleanUpAppEventListener);
            delete(obj.Model);
            delete(obj.MetadataUIViewModel);
        end
    end
end
