classdef (Hidden = true, Sealed = true) PeerModelManagerHelper < handle
    %PeerModelManagerHelper
    %
     
    % Copyright 2020 The MathWorks, Inc.
    
    methods (Access = { ...
            ?viewmodel.internal.factory.CPPVMMFactoryHelper, ...
            ?viewmodel.internal.factory.ManagerFactoryProducer, ...
            })
        function viewModelManager = getViewModelManager(obj, channel, isServerDriven, ~)            
            if nargin < 2
                isServerDriven = false;
            end

            % start peer model
            if isServerDriven
                viewModelManager = com.mathworks.peermodel.PeerModelManagers.getServerInstance(channel);
            else
                viewModelManager = com.mathworks.peermodel.PeerModelManagers.getClientInstance(channel);
            end
            viewModelManager.setSyncEnabled(true);           
        end
        
        function cleanup(~, namespace, varargin)
            com.mathworks.peermodel.PeerModelManagers.cleanup(namespace);
        end
    end
    
    methods (Static, Access = public)
        
        function isVM = isViewModel(viewModelObject)
            import viewmodel.internal.factory.PeerModelManagerHelper;
            
            isVM = (PeerModelManagerHelper.isViewModelObject(viewModelObject) || ...
                    PeerModelManagerHelper.isViewModelManager(viewModelObject) ...
                    );
        end
       
        function isViewModelObject = isViewModelObject(object)
            isViewModelObject = isa(object, 'com.mathworks.peermodel.PeerNode');
        end
        
        function isViewModelManager = isViewModelManager(object)
            isViewModelManager = isa(object, 'com.mathworks.peermodel.PeerModelManager');
        end        
    end
end

