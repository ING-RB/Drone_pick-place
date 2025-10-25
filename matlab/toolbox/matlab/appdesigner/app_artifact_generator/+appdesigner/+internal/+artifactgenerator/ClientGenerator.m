classdef ClientGenerator < handle & ...
        matlab.ui.internal.componentframework.services.optional.ControllerInterface % For accessing getControllerHandle()
    %CLIENTGENERATOR

%   Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        ClientCacheSubFolder = "client";
        ClientCacheFileName = "appViewCache.json";
    end

    methods (Access = public)
        function success = generateClientCache (obj, fig, bucket, async)
            arguments
                obj 
                fig 
                bucket 
                async = true; 
            end
            [~, clientPath] = bucket.addFolder(obj.ClientCacheSubFolder);

            function genAndWriteCache()
                matlab.graphics.internal.drawnow.startUpdate;
                data = obj.getData(fig);

                if ~isempty(data)
                    % Do not pretty print if we are not in MW env
                    prettyPrint = ~isempty(getenv("MW_INSTALL"));

                    viewCacheFullFile = fullfile(clientPath, obj.ClientCacheFileName);

                    fid = fopen(viewCacheFullFile,  "w", "n", "utf-8");
                    fprintf(fid, "%s", jsonencode(appdesservices.internal.peermodel.convertStructToJSONCompatible(data, {'string'}), PrettyPrint=prettyPrint));
                    fclose(fid);
                end
            end

            viewCacheRelativePath = fullfile(obj.ClientCacheSubFolder, obj.ClientCacheFileName);
            if ~bucket.containsFile(viewCacheRelativePath)
                if async && ~isdeployed
                    appdesigner.internal.async.AsyncTask(@genAndWriteCache).run();
                else
                    genAndWriteCache();
                end
            end

            success = true;
        end
    end

    methods (Access = private)
        function data = getData (obj, fig)
            figController = fig.getControllerHandle();
            if isempty(figController) || ~isvalid(figController)
                data = struct.empty();
                return;
            end

            viewProps = obj.getComponentViewPropsDuringConstruction(fig, figController);
            data = struct('Type', class(fig), 'PropertyValues', viewProps, 'Children', obj.getComponentData(obj.getChildren(fig, figController)));
        end

        function children = getChildren(~, parent, parentCtrl)
            % Remove axes from children list
            % Remove components without dynamic property - 'AD_CodeName'            
            findallParams = {'-property', 'AD_CodeName', '-not','Type', 'axes'};
            children = appdesservices.internal.interfaces.view.ViewModelFactory.getAllChildren(parent, parentCtrl, findallParams);
        end

        function data = getComponentData (obj, children)
            count = length(children);

            data = [];
            for i = count : -1 : 1
                model = children(i);
                controller = model.getControllerHandle();

                if  ~isvalid(model) || isa(model, 'matlab.ui.control.UIAxes') || isempty(controller)
                    % Since writing is in an sync task, app may be closed when it's going to generate cache.
                    % Axes does not have view properties to do client-first rendering
                    % TreeNode has no controller
                    continue;
                end

                props = obj.getComponentViewPropsDuringConstruction(model, controller);
                if isempty(data)
                    data = struct('Type', [], 'PropertyValues', []);
                end
                data(i).Type = class(model);
                data(i).PropertyValues = props;

                grandChildren = obj.getChildren(model, controller);
                if ~isempty(grandChildren)
                    data(i).Children = obj.getComponentData(grandChildren);
                end
            end
        end

        function viewProps = getComponentViewPropsDuringConstruction (~, model, controller)
            viewProps = controller.retrieveCachedPropertiesForViewDuringConstruction().PropertyValues;
            
            if isa(model, 'matlab.ui.container.Tab')
                % Store AD_Selected to set selected Tab during client-first rendering
                if eq(model, model.Parent.SelectedTab)
                    viewProps.AD_Selected = true;
                end
            end
            viewProps.AD_CodeName = model.AD_CodeName;
        end
    end
end
