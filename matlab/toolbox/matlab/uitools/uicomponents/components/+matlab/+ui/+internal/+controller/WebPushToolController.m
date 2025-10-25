classdef WebPushToolController < matlab.ui.internal.controller.WebToolMixinController
    % WebToolbarController Web-based controller for
    % matlab.ui.container.toolbar.PushTool object.
     methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = WebPushToolController(model, varargin )
            %WebPushToolController Construct an instance of this class
            obj = obj@matlab.ui.internal.controller.WebToolMixinController( model, varargin{:} );
        end 
     end
end

