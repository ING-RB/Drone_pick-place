classdef ComponentDataSynchronizer < appdesigner.internal.codegeneration.apptypedatasynchronizer.AbstractAppTypeDataSynchronizer
    %COMPONENTDATASYNCHRONIZER app type data synchronizer used for custom
    %ui components. Applies incoming data from the custom ui component
    %client to the codeModel

    % Copyright 2021, MathWorks Inc.

    methods
        function syncAppTypeData(~, codeModel, codeData)
            % input structure from custom ui component client, see
            % CustomComponentAppTypeData.js for details
            %    {
            %       HasCallbackEvents: [{Name:"", Description: ""}]
            %       Methods: {update: {Name:'update', Code:['']}
            %    }

            codeModel.AppTypeData = struct;

            if isfield(codeData, 'HasCallbackEvents')
                if ~isempty(codeData.HasCallbackEvents)
                    if ~isfield(codeModel.AppTypeData, 'HasCallbackEvents')
                        codeModel.AppTypeData.HasCallbackEvents = struct;
                    end
                end

                for i=1:length(codeData.HasCallbackEvents)
                    codeModel.AppTypeData.HasCallbackEvents(i).Name = codeData.HasCallbackEvents(i).Name;
                    codeModel.AppTypeData.HasCallbackEvents(i).Description = codeData.HasCallbackEvents(i).Description;
                end
            end

            if isfield(codeData, 'Methods')
                if ~isempty(codeData.Methods)
                    if ~isfield(codeModel.AppTypeData, 'Methods')
                        codeModel.AppTypeData.Methods = struct;
                    end

                    % only 'update' is available for UAC, postSetup is
                    % stored in the startupCallback property instead. This
                    % will explicitly pull the expected fields to disk
                    if isfield(codeData.Methods, 'update')
                        codeModel.AppTypeData.Methods.update.Name = codeData.Methods.update.Name;
                        codeModel.AppTypeData.Methods.update.Code = codeData.Methods.update.Code;
                    end
                end
            end

            if isfield(codeData, 'ManagedUserProperties')
                if ~isempty(codeData.ManagedUserProperties)
                    if ~isfield(codeModel.AppTypeData, 'ManagedUserProperties')
                        codeModel.AppTypeData.ManagedUserProperties = struct([]);
                    end
                end

                codeModel.AppTypeData.ManagedUserProperties = codeData.ManagedUserProperties;
            end
            
            % only save value if specified by UI (non default)
            if isfield(codeData, 'AllowTestCaseAccess')
                codeModel.AppTypeData.AllowTestCaseAccess = codeData.AllowTestCaseAccess;                                                
            end
        end
    end

    methods (Access = private)
        function code = transposeCode (~, codeLines)
            % helper method to transpose client code into a cell array, if
            % necessary.

            if ~iscell(codeLines)
                code = codeLines;
            else
                code = {codeLines}';
            end
        end
    end
end
