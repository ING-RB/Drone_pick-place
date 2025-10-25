classdef (Hidden) Layoutable < matlab.ui.internal.mixin.ComponentLayoutable 
    % This undocumented class may be removed in a future release.
    %
    % This class allows components to be parented to 
    % and function property in a layout container.
    %
    % Though this class looks empty, it is required 
    % to allow component authors to develop their components
    % such that they can be parented to a layout container
    % without having to modify C++.

    % Copyright 2017-2018 The MathWorks, Inc.
    
   
    methods
        
        function obj = Layoutable
            obj = obj@matlab.ui.internal.mixin.ComponentLayoutable;
        end
    end
    
end
