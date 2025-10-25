classdef Server < handle
%Server  Represent the backend for code analyzer report.

%   Copyright 2021-2023 The MathWorks, Inc.

    properties (Constant)
        %Map - the map that stores all the server for all the report that
        %are open
        Map containers.Map = containers.Map();
    end
    properties (Dependent)
        %Id - unique identifier for the connecting the backend and the
        %report
        Id
    end
    properties (Hidden)
        %Source - whether this is for an app, from saved object, etc.
        Source char
        %MF0DataModel - the MF0 model that contains the data
        MF0DataModel
        %MessagesModel - the class containing messages, stored in MF0DataModel
        MessagesModel
        %Channel - communication channel that sync MF0 model to the report
        DataChannel
        %Synchronizer - object that provides the MF0 synchronization service
        DataSynchronizer
    end
    properties (Hidden)
        %MF0StatusModel - a small MF0 model that contains the status of the report,
        %this model is intentially small so that it can be sync quickly.
        MF0StatusModel
        %StatusModel - the class containing the status information, stored in the MF0StatusModel
        StatusModel
        %StatusChannel - communication channel that sync small model to the report
        StatusChannel
        %StatusSynchronizer - object that provides the MF0 synchronization service
        StatusSynchronizer
    end
    methods (Access = {?codeIssues})
        function obj = Server(mf0DataModel, messagesModel, mf0StatusModel, statusModel, source)
            arguments
                mf0DataModel mf.zero.Model
                messagesModel matlab.codeanalyzer.internal.datamodel.MessagesModel
                mf0StatusModel mf.zero.Model
                statusModel matlab.codeanalyzer.internal.datamodel.StatusModel
                source char
            end
            mlock; % prevent this file and the map to be cleared.

            % store information
            obj.MF0DataModel = mf0DataModel;
            obj.MessagesModel = messagesModel;
            obj.Source = source;

            % Add more information for report
            txn = mf0DataModel.beginTransaction;
            obj.MessagesModel.id = getUUID(matlab.codeanalyzerreport.internal.Server.Map);
            obj.MessagesModel.progressChannel = "/codeanalyzerreport/responseChannel/progress/" + obj.MessagesModel.id;
            obj.MessagesModel.cancelChannel = "/codeanalyzerreport/requestChannel/cancel/" + obj.MessagesModel.id;
            obj.MessagesModel.initialize();
            obj.MessagesModel.changeInputEvent.registerHandler(@(src, evt) changeInputCallback(src, evt));
            obj.MessagesModel.analysisDoneEvent.registerHandler(@(src, status, ~) analysisDoneCallback(obj, src, status));
            txn.commit;

            obj.MF0StatusModel = mf0StatusModel;
            obj.StatusModel = statusModel;
            obj.StatusModel.initialize();

            % Add server into the map to be stored.
            obj.Map(obj.Id) = obj;

            % start synchronizing the model
            statusChannel = "/codeanalyzermodel/statusChannel/" + obj.Id;
            obj.StatusChannel = mf.zero.io.ConnectorChannelMS(statusChannel, statusChannel);
            obj.StatusSynchronizer = mf.zero.io.ModelSynchronizer(mf0StatusModel, obj.StatusChannel);
            obj.StatusSynchronizer.start();

            channel = "/codeanalyzermodel/channel/" + obj.Id;
            obj.DataChannel = mf.zero.io.ConnectorChannelMS(channel, channel);
            obj.DataSynchronizer = mf.zero.io.ModelSynchronizer(mf0DataModel, obj.DataChannel);
            obj.DataSynchronizer.start();
        end
        function delete(obj)
            % stop synchronizing the model
            if ~isempty(obj.DataSynchronizer)
                obj.DataSynchronizer.stop();
            end
        end
    end
    methods (Hidden)
        % Converter method to convert code analyzer backend Server
        % to codeIssues
        function issues = codeIssues(obj)
            model = obj.MessagesModel.clone();
            issues = codeIssues(model);
        end
    end
    methods
        function id = get.Id(obj)
            id = obj.MessagesModel.id;
        end
        function newUrl = getUrl(obj)
            newUrl = connector.getUrl("toolbox/matlab/codeanalysis/analyzerrpt/web/analyzerrpt/index.html" ...
                + "?clientid=" + obj.Id + "&source=" + obj.Source);
        end
        function launchReport(obj, options)
            arguments
                obj matlab.codeanalyzerreport.internal.Server
                options.NewTab = true;
            end
            url = getUrl(obj);
            h = htmlviewer(url, NewTab=options.NewTab, ShowToolbar=false);
            if obj.StatusModel.isCompatibilityReport
                h.Title = getString(message("matlab_toolbox_analyzerrpt:labels:ccrTitle"));
            else
                h.Title = getString(message("matlab_toolbox_analyzerrpt:labels:reportTitle"));
            end
        end
    end
    methods (Static)
        server = create(items, options);
        close(uuid);
    end
end

function uuid = getUUID(map)
    [~, uuid] = fileparts(tempname);
    while (isKey(map, uuid))
        [~, uuid] = fileparts(tempname);
    end
end

function changeInputCallback(src, evt)
    try
        resolveInput(src, evt);
        src.folderInputDoneEvent.emit();
        src.rerunEvent.emit();
    catch e
        src.analysisDoneEvent.emit('error', e.message);
    end
end

function analysisDoneCallback(obj, src, evt)
    if evt == "finished"
        obj.StatusModel.initialized = true;
        obj.StatusModel.numMessages = numel(src.getActiveMessages());
    end
end
