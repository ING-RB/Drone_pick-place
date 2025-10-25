classdef (Hidden = true, Sealed = true) CPPVMMFactoryHelper < handle
    %CPPVMMFactoryHelper
    %
     
    % Copyright 2020-2023 The MathWorks, Inc.
    
    methods (Access = { ...
            ?viewmodel.internal.factory.CPPVMMFactoryHelper, ...
            ?viewmodel.internal.factory.ManagerFactoryProducer, ...
            })
        function viewModelManager = getViewModelManager(~, channel, ~, commitStrategy)
            if nargin < 4
                commitStrategy = 'auto';
            end
            viewModelManager = viewmodel.internal.ViewModelManagerFactory.getViewModelManager(channel, commitStrategy);            
        end
        
        function cleanup(~, channel, varargin)
            if (viewmodel.internal.ViewModelManagerFactory.hasViewModelManager(channel))
                delete(viewmodel.internal.ViewModelManagerFactory.getViewModelManager(channel));
            end
        end
    end
    
    methods (Static, Access = public)
        function isVM = isViewModel(viewModelObject)
            import viewmodel.internal.factory.CPPVMMFactoryHelper;
            
            isVM = (CPPVMMFactoryHelper.isViewModelObject(viewModelObject) || ...
                    CPPVMMFactoryHelper.isViewModelManager(viewModelObject) ...
                    );
        end
       
        function isViewModelObject = isViewModelObject(object)
            isViewModelObject = isa(object, 'viewmodel.internal.ViewModel');
        end
        
        function isViewModelManager = isViewModelManager(object)
            isViewModelManager = isa(object, 'viewmodel.internal.ViewModelManager');
        end
    end
end

