classdef AbstractUI < handle & matlab.mixin.Heterogeneous & controllib.ui.internal.dialog.MixedInDataListeners & controllib.ui.internal.dialog.MixedInUIListeners
    % Master super class for AbstractDialog and AbstractPanel
    % It provides Data/UI event listener management for dialog and panel
    %
    % AbstractDialog and AbstractPanel wrap "uifigure" and "ui container"
    % objects respectively.
    
    % Author(s): Rong Chen
    % Copyright 2019 The MathWorks, Inc.
    
    %% Public methods
    methods
        
        function updateUI(this)
            % Method "updateUI": 
            %
            %   Programmatically update/refresh UI based on data source.
            %
            %   updateUI(this)
            %
            %   Subclass should overload this method.
        end
    
        function delete(this)
            % delete all the data and UI listeners
            unregisterDataListeners(this);
            unregisterUIListeners(this);
            % force to clean up UI
            cleanupUI(this)
        end
        
    end
    
    %% Protected methods
    methods(Access = protected)
        
        function connectUI(this) %#ok<*MANU>
            % Method "connectUI": 
            %
            %   Add listeners to events from data sources and/or UI widgets.  
            %
            %   connectUI(this)
            %
            %   Subclass should overload this method.
            %
            %   This method is automatically called during rendering.
        end
        
        function cleanupUI(this)
            % Method "cleanupUI": 
            %
            %   Additional clean up efforts when this object is deleted.  
            %
            %   cleanupUI(this)
            %
            %   Subclass should overload this method.
        end
        
    end
    
    %% Below this line are properties and methods for QE use only
    methods (Hidden)
       
        function widgets = qeGetWidgets(this)
            % Method "connectUI": 
            %
            % Return UI components embedded inside this object for QE to
            % access.
            %
            %   widgets = qeGetWidgets(this)
            %
            %   Subclass should overload this method to provide QE support.
            %
            %   This method is used by test points.
            widgets = [];
        end
        
    end
        
end