classdef AppChildModelFactory < appdesservices.internal.interfaces.model.DesignTimeModelFactory
    % AppChildModelFactory  Factory to create children of the AppModel

    % Copyright 2013-2023 The MathWorks, Inc.

    methods
        function model = createModel(obj, parentModel, peerNode)
            % create a model with the proxyView as a child of the parentModel

            type = char(peerNode.getType());
            switch (type)
                case 'matlab.ui.Figure'
                    factory = appdesigner.internal.componentmodel.DesignTimeComponentFactory;
                    model = ...
                        factory.createModel(...
                        parentModel, ...
                        peerNode);

                case 'CodeData'
                    % Create the proxyView for this child peerNode
                    proxyView = ...
                        appdesigner.internal.view.DesignTimeProxyView(peerNode);
                    model = appdesigner.internal.codegeneration.model.CodeModel(parentModel, proxyView);

                case 'RunModel'
                    % Create the proxyView for this child peerNode
                    proxyView = ...
                        appdesigner.internal.view.DesignTimeProxyView(peerNode);
                    model = appdesigner.internal.runarguments.model.RunArgumentsModel(parentModel, proxyView);

                case 'MetaDataModel'
                    proxyView = ...
                        appdesigner.internal.view.DesignTimeProxyView(peerNode);
                    model = appdesigner.internal.model.MetadataModel(parentModel, proxyView);

                case 'Code'
                    model = 'Code';

                case 'InspectableApp'
                    model = 'InspectableApp';

                case 'SimulinkModel'
                    proxyView = ...
                        appdesigner.internal.view.DesignTimeProxyView(peerNode);
                    model = appdesigner.internal.model.SimulinkModel(parentModel, proxyView);

                case 'GroupsManager'
                    proxyView = ...
                        appdesigner.internal.view.DesignTimeProxyView(peerNode);
                    model = appdesigner.internal.model.GroupsModel(parentModel, proxyView);

                otherwise
                    assert(false,sprintf('Unhandled proxyView type: %s', type));
            end
        end
    end
end
