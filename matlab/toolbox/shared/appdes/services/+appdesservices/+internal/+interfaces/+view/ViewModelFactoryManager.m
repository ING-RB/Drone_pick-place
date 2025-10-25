classdef (Hidden) ViewModelFactoryManager < handle
    %VIEWMODELFACTORYMANAGER A single instance to get current ViewModelFactory
    % instance to be used to create ViewModel objects

    % Copyright 2023 - 2024 MathWorks, Inc.

     properties(Constant)
        % Singleton instance of the class
        Instance = appdesservices.internal.interfaces.view.ViewModelFactoryManager;
    end
    
    properties 
        ViewModelFactory = appdesservices.internal.interfaces.view.ViewModelFactory;
    end

    methods
        function factory = getViewModelFactory(obj, model, ctrl, parentCtrl)
            arguments
                obj 
                model = [];
                ctrl = [];
                parentCtrl = [];
            end
  
            clientFirstRendering = false;
            isFigure = false;
            
            if ~isempty(model) && isa(model, "matlab.ui.Figure")
                isFigure = true;
                clientFirstRendering = matlab.ui.internal.FigureServices.isClientFirstRendering(model);
            end

            if clientFirstRendering && isFigure
                factory = appdesservices.internal.interfaces.view.ClientFirstRenderingViewModelFactory(model, ctrl.getAdditionalPropertiesToSetOnFigureViewModel());
            else
                if ~isempty(parentCtrl) && ~isempty(parentCtrl.ViewModelFactory)                    
                    factory = parentCtrl.ViewModelFactory;
                else
                    % Under test and UAC, it could be empty
                    factory = obj.ViewModelFactory;
                end
            end
        end
    end

    methods (Access = 'private')
        % Private constructor 
        function obj = ViewModelFactoryManager
             % put an mlock in this constructor to avoid any of the "clear"
            % commands from freeing up the Instance.
            mlock;
        end  
    end
end
