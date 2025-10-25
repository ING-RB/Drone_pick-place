classdef WebDispatcher < matlab.uiautomation.internal.UIDispatcher
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    methods (Access = ?matlab.uiautomation.internal.UIDispatcher)
        function dispatcher = WebDispatcher()
        end
    end

    methods
        function dispatch(~, model, evtName, varargin)
            if(isa(model, 'matlab.ui.container.internal.AppContainer'))
                dispatcher = matlab.uiautomation.internal.dispatchers.AppContainerWebDispatcher;
            else
                dispatcher = matlab.uiautomation.internal.dispatchers.FigureWebDispatcher;
            end
            dispatcher.dispatch(model, evtName, varargin{:});
        end
    end

    methods(Access=protected, Static)
        function parser = parseInputs(varargin)
            import matlab.uiautomation.internal.Buttons;
            
            parser = inputParser;
            parser.KeepUnmatched = true;
            parser.addParameter('Modifier', []);
            parser.addParameter('Button', Buttons.LEFT);
            parser.parse(varargin{:});
        end

        function s = mapOptions(modifier, button)
            % Map Driver-independent options to Web-view-specifics
            
            import matlab.uiautomation.internal.Modifiers;
            
            modFields = {'ctrlKey',    'shiftKey',      'altKey',    'metaKey'};
            modEnums =  [Modifiers.CTRL Modifiers.SHIFT Modifiers.ALT Modifiers.META];
            
            opts = unique(modifier);
            modValues = ismember(modEnums, opts);
            
            s = cell2struct(num2cell(modValues), modFields, 2);
            s.button = uint8(button);
        end
    end
    
end


% LocalWords:  uitest appcontainer
