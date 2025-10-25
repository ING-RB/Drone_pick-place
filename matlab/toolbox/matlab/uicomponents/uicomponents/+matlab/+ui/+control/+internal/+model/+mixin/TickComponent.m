classdef (Hidden) TickComponent < appdesservices.internal.interfaces.model.AbstractModelMixin
    
    % This undocumented class may be removed in a future release.
    
    % This is the parent class for all components with ticks.
    %
    % It provides all properties for handling ticks.
    
    % Copyright 2011 The MathWorks, Inc.
    
    properties(Dependent)        
        MajorTicks = 0:20:100;
        
        MinorTicks;
        
        MajorTickLabels = {};
    end
    
    properties(Dependent, NeverAmbiguous, AbortSet)
        MajorTicksMode = 'auto';
        
        MinorTicksMode = 'auto';
        
        MajorTickLabelsMode = 'auto';
    end
    
    properties(Access = 'private')
        
        % Number of Minor Ticks between largest Major Tick interval
        MinorTickCount = 4;
        
        % The length of the scale line by default
        ScaleLineLength = 100;
        
    end
    
    properties(Access = {...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.controller.AbstractController})
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivateMajorTicks = 0:20:100;
        
        PrivateMinorTicks; % Default generated in view
        
        PrivateMajorTickLabels = {}; % Default generated in constructor
        
    end
    
    properties(Access = 'protected')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, beacuse sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivateMajorTicksMode = 'auto';
        
        PrivateMajorTickLabelsMode = 'auto';
        
        PrivateMinorTicksMode = 'auto';
    end
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = TickComponent(varargin)
            
            % Handle any dependent properties updates based on initial
            % MajorTick value. We want specific MATLAB formatted labels,
            % so update the labels on the server
            if isequal(obj.MajorTickLabelsMode, 'auto')
                autoUpdateMajorTickLabels(obj, obj.PrivateMajorTicks)
            end           
        end
    end
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        
        function set.MajorTicks(obj, newValue)
            
            obj.doSetMajorTicks(newValue);
            
            obj.PrivateMajorTicksMode = 'manual';
            
            % We want specific MATLAB formatted labels, so update the
            % labels on the server
            if isequal(obj.PrivateMajorTickLabelsMode, 'auto')
                
                % Update to View
                markPropertiesDirty(obj, {'MajorTicks', 'MajorTicksMode','MajorTickLabels'});
            else
                
                % Update View
                markPropertiesDirty(obj, {'MajorTicks', 'MajorTicksMode'});
            end
        end
        
        function majorTicks = get.MajorTicks(obj)
            majorTicks = obj.PrivateMajorTicks;
        end
        
        function set.MajorTicksMode(obj, newValue)
            % Error Checking
            try
                newMode = matlab.ui.control.internal.model.PropertyHandling.processMode(obj, newValue);
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidTwoStringEnum', ...
                    'MajorTicksMode', 'auto', 'manual');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidMajorTicksMode';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivateMajorTicksMode = newMode;
            
            
            % Update View,
            % When in auto mode, MajorTicks are recalculated on the client
            markPropertiesDirty(obj, {'MajorTicksMode'});
            
        end
        
        function majorTickMode = get.MajorTicksMode(obj)
            majorTickMode = obj.PrivateMajorTicksMode;
        end
        
        function set.MinorTicks(obj, newValue)
            
            % Error Checking
            tickPropertyName = 'MinorTicks';
            
            newMinorTicks = matlab.ui.control.internal.model.PropertyHandling.validateTickArray(obj, newValue, tickPropertyName);
            
            % Property Setting
            obj.PrivateMinorTicks = newMinorTicks;
            obj.PrivateMinorTicksMode = 'manual';
            
            % Update View
            markPropertiesDirty(obj, {'MinorTicks', 'MinorTicksMode'});
        end
        
        function minorTicks = get.MinorTicks(obj)
            minorTicks = obj.PrivateMinorTicks;
        end
        
        function set.MinorTicksMode(obj, newValue)
            % Error Checking
            try
                newMode = matlab.ui.control.internal.model.PropertyHandling.processMode(obj, newValue);
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidTwoStringEnum', ...
                    'MinorTicksMode', 'auto', 'manual');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidMinorTicksMode';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivateMinorTicksMode = newMode;
            
            % Update View
            markPropertiesDirty(obj, {'MinorTicksMode'});
            
        end
        
        function minorTickMode = get.MinorTicksMode(obj)
            minorTickMode = obj.PrivateMinorTicksMode;
        end
        
        function set.MajorTickLabels(obj, majorTickLabels)
            % Error Checking
            doSetMajorTickLabels(obj, majorTickLabels)
            
            % Dependent Property Setting
            obj.PrivateMajorTickLabelsMode = 'manual';
            
            obj.markPropertiesDirty({'MajorTickLabels', 'MajorTickLabelsMode'});
        end
        
        function majorTickLabels = get.MajorTickLabels(obj)
            majorTickLabels = obj.PrivateMajorTickLabels;
        end
        
        function set.MajorTickLabelsMode(obj, newValue)
            % Error Checking
            try
                newMode = matlab.ui.control.internal.model.PropertyHandling.processMode(obj, newValue);
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidTwoStringEnum', ...
                    'MajorTickLabelsMode', 'auto', 'manual');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidMajorTickLabelsMode';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivateMajorTickLabelsMode = newMode;
            
            if isequal(obj.PrivateMajorTickLabelsMode, 'auto')
                autoUpdateMajorTickLabels(obj, obj.PrivateMajorTicks)
                
                % Update to View
                markPropertiesDirty(obj, {'MajorTickLabelsMode', 'MajorTickLabels'});
            else
                % Update to View
                markPropertiesDirty(obj, {'MajorTickLabelsMode'});
            end
        end
        
        function majorTickLabelsMode = get.MajorTickLabelsMode(obj)
            majorTickLabelsMode = obj.PrivateMajorTickLabelsMode;
        end
        
    end
    
    
    % ---------------------------------------------------------------------
    % Tick / Label Generating Functions
    % ---------------------------------------------------------------------
    
    methods (Access = 'private')
        
        function autoUpdateMajorTickLabels(obj, majorTicks)
            % We want specific MATLAB formatted labels, so update the
            % labels on the server
            
            majorTickLabels = matlab.ui.control.internal.model.PropertyHandling.convertArrayToLabels(majorTicks);
            obj.doSetMajorTickLabels(majorTickLabels);
        end
        
    end
    
    methods(Access = {?matlab.ui.control.internal.controller.mixin.TickComponentController})
        % These methods support workflows where the client changes the
        % values of these three properties.  Having these methods allows us
        % to handle specially when the property changes are happening from
        % the client as opposed to the commandline
        
        % Update MajorTicks & only mark MajorTickLabels dirty if MajorTickLablesMode
        % is 'auto' - check mode coming from controller event data g1700885
        function handleMajorTicksChanged(obj, majorTicks, majorTickLabelsMode)
            doSetMajorTicks(obj, majorTicks, majorTickLabelsMode);
            % We want specific MATLAB formatted labels, so push the
            % labels to the client
            if isequal(majorTickLabelsMode, 'auto')
                markPropertiesDirty(obj, {'MajorTickLabels'});
            end
        end
        
        function handleMinorTicksChanged(obj, minorTicks)
            doSetMinorTicks(obj, minorTicks);
        end
        
        function handleMajorTickLabelsChanged(obj, majorTickLabels)
            doSetMajorTickLabels(obj, majorTickLabels);
        end
    end
    
    methods (Access = protected)
        
        function doSetMajorTicks(obj, majorTicks, majorTickLabelsMode)
            
            % Error Checking
            tickPropertyName = 'MajorTicks';
            
            % When MajorTicks set through public api
            % use the PrivateMajorTickLabelsMode to determine
            % MajorTickLabelsMode when set through handleMajorTicksChanged,
            % use the majorTickLabelsMode 
            if (nargin == 2)
                majorTickLabelsMode = obj.PrivateMajorTickLabelsMode;
            end
            
            newMajorTicks = matlab.ui.control.internal.model.PropertyHandling.validateTickArray(obj, majorTicks, tickPropertyName);
            
            % Property Setting - Major ticks are sorted before being set
            obj.PrivateMajorTicks = sort(newMajorTicks);
            
            % We want specific MATLAB formatted labels, so update the
            % labels on the server
            if isequal(majorTickLabelsMode, 'auto')
                autoUpdateMajorTickLabels(obj, obj.PrivateMajorTicks)
            end
        end
    end
    methods (Access = private)
        function doSetMinorTicks(obj, minorTicks)
            obj.PrivateMinorTicks = minorTicks;
        end
        
        function doSetMajorTickLabels(obj, majorTickLabels)
            
            % Error Checking
            try
                newTickLabels = matlab.ui.control.internal.model.PropertyHandling.processCellArrayOfStrings(...
                    obj, ...
                    'MajorTickLabels', ...
                    majorTickLabels, ...
                    [0, Inf]);
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidMajorTickLabels', ...
                    'MajorTickLabels');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidMajorTickLabels';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivateMajorTickLabels = newTickLabels;
            
        end
        
    end
    
end



