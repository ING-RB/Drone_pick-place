classdef PluginBase < matlab.mixin.Heterogeneous & handle
    %PLUGINBASE Summary of this class goes here
    % Heterogeneous mixin base class to allow different plugin classes to
    % extend from. Make this an explicit handle class.
    
    % Copyright 2019-2024 The MathWorks, Inc.
    properties (WeakHandle)
        ViewModel internal.matlab.variableeditor.ViewModel = internal.matlab.variableeditor.ArrayViewModel.empty;
    end

    properties
        NAME string
    end

    methods
        function this=PluginBase(viewModel)
            this.ViewModel = viewModel;
        end
    end
    
end

