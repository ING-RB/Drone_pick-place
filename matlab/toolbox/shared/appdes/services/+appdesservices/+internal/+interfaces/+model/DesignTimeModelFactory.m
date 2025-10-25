classdef DesignTimeModelFactory < handle
    % DesignTimeModelFactory An abstract base class for model factories

    methods(Abstract)
        % create a model given a parent and proxyView
        model = createModel(obj, parentModel,proxyView)
    end  
end
