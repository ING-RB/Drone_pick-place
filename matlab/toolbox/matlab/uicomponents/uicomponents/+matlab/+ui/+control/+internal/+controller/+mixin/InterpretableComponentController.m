classdef (Hidden) InterpretableComponentController <  appdesservices.internal.interfaces.controller.AbstractControllerMixin
    % Mixin Controller Class for Interpretable Components

    % Copyright 2011-2023 The MathWorks, Inc.

    methods(Access = 'protected')
        function handleEvent(obj, src, event)
            if(strcmp(event.Data.Name, 'LinkClicked'))
                % Execute URL
                url = '';
                if isfield(event.Data, 'URL')
                    url = event.Data.URL;
                end

                if ~isempty(url) && event.Data.TreatAsMATLABLink
                    try
                        web(url, '-browser')
                    catch me
                        % MnemonicField is last section of error id
                        mnemonicField = 'failureToLaunchURL';

                        messageObj = message('MATLAB:ui:components:errorInWeb', ...
                        url, me.message);  

                        warning(['MATLAB:ui:Label:' mnemonicField], messageObj.getString())
                    end

                else
                    %Invalid web url
                    %Empty url has 2 possible causes
                    % 1. User provided empty url
                    % 2. User provided invalid protocol that was sanitized

                    mnemonicField = 'failureToLaunchWebURL';
                    messageObj = message('MATLAB:ui:components:errorInWebEmpty');
                    warning(['MATLAB:ui:Label:' mnemonicField], messageObj.getString())

                end
            end
        end
    end
end