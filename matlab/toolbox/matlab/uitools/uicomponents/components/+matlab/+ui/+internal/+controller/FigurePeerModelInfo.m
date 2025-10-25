classdef FigurePeerModelInfo < handle
    
    % FigurePeerModelInfo object that sets up the PeerModel infrastructure used by the FigureController
    % and its PlatformHost
    % Todo:
    %     Since it's now called ViewModel, instead of PeerModel, it's better 
    %     to delete or rename this file. However, this has been used by lots of tests,
    %     will keep this one for now with moving logic out of it, just maintaining
    %     passing data that are required by tests or some areas of software.

    % Copyright 2016-2024 The MathWorks, Inc.
    
    properties (SetAccess = private)
        URL = [];            % Full URL
        HTMLFile;
        DebugPort;
        FigurePeerNode;
        Id = [];             % Figure ViewModel Id
        PeerModelManager;
        PeerModelRoot;
        PeerModelChannel;
        AdditionalFigurePropsOnViewModel;
    end

    properties (Constant)
        FigureURLBasePath = 'toolbox/matlab/uitools/uifigureappjs/';
    end

    properties (Access = private)
        FigureModel;
    end

    methods
        % constructor
        function obj = FigurePeerModelInfo(htmlFile, channel, peerModelManager, figurePeerNode, figureModel, additionalFigurePropsOnViewModel)
            arguments
                htmlFile 
                channel 
                peerModelManager
                figurePeerNode
                figureModel
                additionalFigurePropsOnViewModel = struct.empty();
            end
            
            obj.HTMLFile = htmlFile;
            obj.PeerModelChannel = channel;
            obj.PeerModelManager = peerModelManager;
            obj.PeerModelRoot = obj.PeerModelManager.getRoot();
            obj.FigurePeerNode = figurePeerNode;
            obj.Id = char(obj.FigurePeerNode.getId);
            
            obj.FigureModel = figureModel;
            obj.AdditionalFigurePropsOnViewModel = additionalFigurePropsOnViewModel;

            % debug port is random.  "getOpenPort()" returns 0 (disabling debug port) in the shipped ML.
            obj.DebugPort = matlab.internal.getDebugPort();            
        end % constructor

        function url = get.URL(obj)
            if isempty(obj.URL)
                obj.URL = obj.constructFigureURL(obj.HTMLFile, obj.PeerModelChannel, obj.FigureModel, obj.AdditionalFigurePropsOnViewModel);
            end

            url = obj.URL;
        end        
    end % public methods

    methods (Access = private)
        function url = constructFigureURL(obj, htmlFile, channel, fig, addtionalFigurePropsOnViewModel)
            arguments
                obj 
                htmlFile 
                channel
                fig
                addtionalFigurePropsOnViewModel
            end
            pathToHtmlFile = strcat(obj.FigureURLBasePath, htmlFile);

            % ensure connector is on and get URL
            connector.ensureServiceOn();

            queryParam = ['?channel=', char(channel), ...
                '&websocket=on'];

            dataForClient = matlab.ui.internal.FigureServices.getClientFirstRenderingDataForClient(fig, addtionalFigurePropsOnViewModel);
            if ~isempty(dataForClient)
                fdNames = fieldnames(dataForClient);

                for ix = 1 : numel(fdNames)
                    key = fdNames{ix};

                    queryParam = [queryParam, '&',...
                        key, '=', urlencode(jsonencode(dataForClient.(key)))];
                end
            end

            url = connector.getUrl(['/', pathToHtmlFile, ...
                queryParam]);
        end
    end

    methods (Access = {?matlab.ui.internal.controller.FigureController })
        function updateFigureURL(this, newURL)
            this.URL = newURL;
        end
    end
    
    methods (Access = {?gbttest.util.FigureControllerTestHelper})
        
        % getTestHelperInfo() - called by FigureControllerTestHelper to get a struct containing data it uses
        function testHelperInfo = getTestHelperInfo(this)
            testHelperInfo.URL = this.URL;
            testHelperInfo.DebugPort = this.DebugPort;
            testHelperInfo.PeerModelManager = this.PeerModelManager;
            testHelperInfo.PeerNode = this.FigurePeerNode;
            testHelperInfo.Id = char(this.Id);
        end % getTestHelperInfo()
        
    end % limited access methods
end