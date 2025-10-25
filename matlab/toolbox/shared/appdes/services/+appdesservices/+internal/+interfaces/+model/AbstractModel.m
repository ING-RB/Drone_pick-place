classdef (Hidden) AbstractModel < ...
        matlab.mixin.SetGet

    % ABSTRACTMODEL is an abstraction for a model, the M in MVC.
    %
    % AbstractModel provides the following:
    %
    % - Models may dirty properties by using the markPropertiesDirty()
    %   method, which will tell this class to pass fresh property values to
    %   controllers.
    %

    % Copyright 2012 - 2020 MathWorks, Inc.

    properties (Access = 'private')
        % Strategy that defines how dirty properties are to be handled.
        DirtyPropertyStrategy
    end

    methods
        function obj = AbstractModel()
            % The default DirtyPropertyStrategy is the NoOp one (which performs no flush).
            % This can be changed later via setDirtyPropertyStrategy().
            obj.DirtyPropertyStrategy = ...
                appdesservices.internal.interfaces.model.NoOpDirtyPropertyStrategy(obj);
        end
    end

    methods(Access = { ...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin, ...
            ?appdesigner.appmigration.UIControlPropertiesConverter, ...
            ?tDirtyPropertyStrategy})
        function setDirtyPropertyStrategy(obj, strategy)
            obj.DirtyPropertyStrategy = strategy;
        end
    end

    methods(Abstract, Access = 'public', Hidden = true)
        % CREATECONTROLLER(OBJ) creates the controller for the model.
        %
        % 1) For component models
        % This will be called by component framework to initiate the
        % construction of the controller and then the view for runtime
        % component creation.
        %
        % 2) For App Designer specific models
        % This will be called within model's construction to create the
        % controller
        %
        % 'paretnController' is an instance of the parent model's controller
        %
        % - At this time, GBT's parent hierarchy is smart enough to call
        % createController when and only when the parent is ready.
        % The component itself doesnt really have to care, so it makes
        % things simpler.
        controller = createController(obj, parentController)
    end


    % These methods exist to provide a generic way of getting a controller.
    %
    % Defining a 'Controller' property here would clash with HG's
    % definition of a controller.
    methods(Abstract, Access = { ...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.model.AbstractModelMixin, ...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin})

        controller = getController(obj)

        setController(obj, controller)
    end

    properties(Access = 'private')
        % A cell array of properties that have been marked dirty and have
        % not yet been sent to the view
        DirtyProperties = {};
    end

    methods

        function set(obj, varargin)
            set@matlab.mixin.SetGet(obj, varargin{:});
        end

        function delete(obj)
            % This will start the chain of deleting controller -> deleting
            % view
            controller = obj.getController();
            if(~isempty(controller) && isvalid(controller))
                delete(controller);
            end
        end
    end

    methods(Access = {...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin, ...
            })

        function resetDirtyProperties(obj)
            % Reset the dirty properties
            obj.DirtyProperties = {};
        end
    end

    methods(Access = 'protected')

        function isDirty = isInDirtyProperties(obj, propertyName)
            % Returns whether the given property is in the list of dirty properties.
            isDirty  = contains(propertyName, obj.DirtyProperties);
        end

    end

    methods(Access = {...
            ?appdesservices.internal.interfaces.model.AbstractDirtyPropertyStrategy, ...
            ?matlab.ui.container.internal.model.ContainerModel, ...
            ?matlab.ui.control.internal.model.ComponentModel, ...
            ?matlab.ui.internal.controller.uicontrol.RedirectStrategyInterface })

        function flushDirtyProperties(obj)
            if isvalid(obj)
                % This will sends all dirty properties to the view
                %
                % Dirty properties are the properties currently stored in
                % 'DirtyProperties' property

                % Figure out what changed
                changedProperties = obj.DirtyProperties;

                % Reset what is dirty
                obj.resetDirtyProperties();

                % Send dirty properties to controller if it exists
                controller = obj.getController();
                if ~isempty(controller)
                    controller.updateProperties(changedProperties);
                end
            end
        end

    end

    % Controller - related methods
    methods(Access = {...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin, ...
            ?appdesservices.internal.interfaces.controller.DesignTimeParentingController, ...
            ?appdesservices.internal.interfaces.view.AbstractProxyViewFactory,...
            ?appdesservices.internal.interfaces.model.AbstractModel,...
            ?appdesservices.internal.interfaces.model.ParentingModel}, ...
            Sealed = true)

        function [model, idx] = byId(obj, idToLookFor)
            % convenience function to return the model by given ID

            model = [];

            for idx = 1:length(obj)

                % Get the id of this object from the controller
                id = obj(idx).getController().getId();

                % See if this id matches the one we are looking for
                if(strcmp(id, idToLookFor))
                    model = obj(idx);
                    break;
                end
            end
        end
    end

    % Model - related methods
    methods(Access = {...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.model.AbstractModelMixin...
            })

        function parsePVPairs(obj, varargin)
            % Helper method to be used by Model subclasses to:
            %
            % - handle PV Pairs
            % - after, mark the model as fully constructed

            % Parses the PV pairs if there are at least 2 elements in
            % varargin
            if length(varargin) == 1 && ~isstruct(varargin{1}) && (ischar(varargin{1}) || isstring(varargin{1}))
                % g1989239: If only one value is passed as part of the
                % PV pairs (e.g. b = uibutton('Text')) an error should
                % be thrown.  Reusing the InputParser error message here.
                error(message('MATLAB:InputParser:ParamMissingValue', varargin{1}));
            elseif length(varargin) == 1 && ~isstruct(varargin{1})
                % If only one value is passed as part of the PV
                % pairs, but the input is not a string, e.g.
                % matlab.ui.control.Button(fig), throw an error
                errorText = getString(message('MATLAB:ui:components:invalidNameValuePairs', class(obj)));
                errorId = 'MATLAB:class:InvalidArgument';
                exceptionObject = MException(errorId, errorText);
                throw(exceptionObject);
            elseif (nargin > 1)
                % Apply remaining PV Pairs
                %
                % Defer to HG set
                try
                    set(obj, varargin{:});
                catch me
                    % if there is an error while setting any property
                    % after setting the Parent property, the component
                    % would still be added to the Parent (visually) as the Parent
                    % would have a reference to the component.
                    % To prevent this we delete the component obj
                    delete(obj);
                    throw(me);
                end
            end
        end

        function markPropertiesDirty(obj, propertyNames)
            % MARKPROPERTIESDIRTY(OBJ, PROPERTYNAMES) indicates that the
            % given PROPERTYNAMES have changed in the model and should
            % be fowarded along to the controller and eventually the view.
            %
            % Inputs:
            %
            %   propertyNames : Cell array of property names that have
            %                   changed (not the values, just the names)

            obj.markViewPropertiesDirty(propertyNames);

            % Inform figure for property change of component
            obj.notifyPropertyChange(propertyNames);

            % Add whatever properties are dirty to whatever properties are
            % newly dirty
            obj.DirtyProperties = [obj.DirtyProperties propertyNames];

            % Ask the DirtyPropertyStrategy to take any other appropriate action.
            obj.DirtyPropertyStrategy.markPropertiesDirty(propertyNames);

        end
        
    end

    % Model - related methods
    methods(Access = {...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.model.AbstractModelMixin, ...
            ?appdesservices.internal.interfaces.controller.AbstractController})

        function executeUserCallback(obj, matlabEventName, matlabEventData, propertyName, propertyValue)
            % Execute user callbacks associated with 'matlabEventName'.
            % If a property-value pair is also provided, the property will
            % be updated before the callbacks are executed.
            %
            % INPUTS:
            %
            %  - MatlabEventName:  string representing the event that the component
            %                model should emit as a result of the user interaction
            %  - MatlabEventData:  eventdata associated with eventName
            %
            % Example: obj.executeUserCallback('ButtonPushed', 'ButtonPushed', eventData);
            %
            % Optional INPUTS:
            %
            %  - propertyName:    name of the property to be modified as
            %                     a result of the user interaction if any
            %  - propertyValue:   value to update the property to
            %
            % Example: obj.executeUserCallback('ValueChanged', eventData, 'Value', newValue);                        
            
            assert(nargin == 3 || nargin == 5);
            
            if(nargin == 3)
                % There is no property to update, just emit the event
                
                % Have the model emit the event
                % The event handling system will execute the callbacks
                % associated with this event.
                notify(obj, matlabEventName, matlabEventData);
                
            else
                % propertyName and propertyValue were passed in as inputs
                % The property needs to be updated before sending the event
                
                oldValue = obj.(propertyName);
                
                % Check that the property value has indeed changed
                if(isequal(oldValue,propertyValue))
                    % The value has not changed, do not emit event.
                    % This check is a catch all for instances where the
                    % view does send an event even when the value didn't
                    % really change.
                    return;
                end
                
                % Update the property value
                obj.(propertyName) = propertyValue;                                

                % Mark properties dirty
                %
                % Usually, the property is private, such as 'PrivateFoo'
                obj.markPropertiesDirty({propertyName});                 
                
                % Have the model emit the event
                % The event handling system will execute the callbacks
                % associated with this event.
                notify(obj, matlabEventName, matlabEventData);
            end
        end        
    end
end
