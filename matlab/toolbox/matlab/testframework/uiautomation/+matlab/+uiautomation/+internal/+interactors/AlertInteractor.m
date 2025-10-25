classdef AlertInteractor < matlab.uiautomation.internal.interactors.ModalDialogsInteractor
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2023 The MathWorks, Inc.

    properties
        Fig
        Dispatcher
        DialogType = 'uialert'
    end
    
    methods
        function obj = AlertInteractor(actor)
            obj.Fig = actor.Component;
            obj.Dispatcher = actor.Dispatcher;
        end

        function chooseDialog(obj, varargin)
            obj.throwNotSupported('chooseDialog');
        end

        function dismissDialog(obj, varargin)
            narginchk(1, 1);
            obj.Dispatcher.dispatch(obj.Fig, 'dismissDialog', 'dialogType', obj.DialogType);
        end
    end
end