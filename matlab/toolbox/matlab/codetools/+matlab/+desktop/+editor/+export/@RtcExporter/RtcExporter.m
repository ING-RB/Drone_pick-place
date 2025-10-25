classdef RtcExporter < matlab.desktop.editor.export.RtcExporterInterface
%matlab.desktop.editor.export.RtcExporter Base class to exports an RTC
% document with a given ID to the format specified by subclasses.
%
% See subclasses for usage and behavior description.
%

%   Copyright 2020-2021 The MathWorks, Inc.

    %%
    properties
        waitingForResponse
    end

    %%
    methods (Sealed = true)
        function result = export(obj, rtcId, options)
            if ~exist('options', 'var')
                options = struct;
            end
            result = '';

            sendData.contentType = obj.rtcExportInternalFormat;
            try
                sendData.additionalArguments = obj.setup(options);
            catch ME
                throwAsCaller(ME)
            end
            % Keep channels in sync with LiveCodeSaveLoad.js
            sendChannel = strcat('/liveeditor/events/getContentRequest/', rtcId);
            responseChannel = strcat('/liveeditor/events/getContentResponse/', rtcId);

            responseStatus = -1; % No status yet.
            function responseCallback (responseData)
                obj.waitingForResponse = false;
                % Keep the responseData structure in sync with LiveCodeSaveLoad.js.
                % At least we have a status. If it's falsy, we expect an exception.
                % Otherwise we have a content which is format specific.
                responseStatus = responseData.status;
                if responseStatus > 0
                    % JavaScript returned with no error. Pass data through.
                    result = obj.handleResponse(responseData, sendData.additionalArguments);
                else
                    % JavaScript error. Store the exception to expose later.
                    result = responseData.exception;
                end
            end

            handler = message.subscribe(responseChannel, @(msg) responseCallback(msg));
            message.publish(sendChannel, sendData);

            % Wait for result ...
            obj.waitingForResponse = true;
            waitfor(obj, 'waitingForResponse', false);

            % Clean up
            message.unsubscribe(handler);
            obj.cleanup(sendData.additionalArguments);

            if responseStatus < 0
                error('Timeout error.');
            elseif responseStatus == 0
                error(result);
            end

            if isfield(options, 'OpenExportedFile') ...
                    && options.OpenExportedFile ...
                    && isfile(result)
                obj.launch(result);
            end
        end
    end

    %% Overrides from RtcExporterInterface
    methods
        % Override.
        function newoptions = setup(~, oldoptions)
        % Just pass through.
            newoptions = oldoptions;
        end

        % Override.
        function cleanup(~, ~)
        % Default does nothing.
        end
    end

    %%
    methods
        % Helper method to write chars to file.
        function path = writeToFile(~, filePath, data, fopenOpts)
            if nargin < 4
                fopenOpts = {};
            end
            fid = fopen(filePath, 'w', fopenOpts{:});
            fprintf(fid, '%s', data);
            fclose(fid);
            path = filePath;
        end
    end
end
