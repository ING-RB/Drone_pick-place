classdef GroupsModel < handle...
        & appdesigner.internal.model.AbstractAppDesignerModel
    % Copyright 2023 The MathWorks, Inc.

    methods
        function obj = GroupsModel(appModel, proxyView)
            appModel.GroupsModel = obj;

            obj.createController(proxyView);
        end

        function controller = createController(obj,  proxyView)
            controller = appdesigner.internal.controller.DefaultController(obj, proxyView);
            controller.populateView(proxyView);
        end

        function setDataOnSerializer(obj, serializer)
            serializer.Groups = obj.getGroupHierarchy();
        end

        function groupHierarchy = getGroupHierarchy(obj)
            groupHierarchy = {};

            if ~isempty(obj.Controller.ViewModel)
                % There are groups in the app
                groups = obj.Controller.ViewModel.getChildren();

                for index = 1:numel(groups)
                    group = groups(index);
                    groupHierarchy{end+1} = struct('Id', char(group.getId()), ...
                        'ParentGroupId', char(group.getProperty('GroupId')));
                end
            end
        end
    end
end
