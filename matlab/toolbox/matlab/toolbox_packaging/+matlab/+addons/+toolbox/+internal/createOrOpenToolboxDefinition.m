%function createOrOpenToolboxDefinition

    for i=1:10
        if(~isempty(matlab.project.currentProject))
            break;
        end
        pause(0.1);
    end
    projectObj = matlab.project.currentProject;
    
    % User canceled the new project dialog, do nothing and quietly exit
    % TODO: If there was a project open before and the user cancels the
    % dialog, the currently opened project will still be opened.  We need
    % to make sure this is the new project hte user just created to
    % proceed.
    if ~isempty(projectObj)
        
        % Create a new toolbox definition or open an existing one
        try
            tbxConfig = matlab.addons.toolbox.open(projectObj);
        catch
            tbxConfig = matlab.addons.toolbox.new(projectObj);
        end
        
        toolboxDetails = matlab.addons.toolbox.getToolboxDetails(tbxConfig);
        model = toolboxDetails.ModelObj;
    
        %ensure connector is running
        hostInfo = connector.ensureServiceOn;

        %Create a connector channel. The JS UI will expect this to be available
        %when it starts. This is used to pass data to UI and (temporarily) from the
        %UI.
        channel = mf.zero.io.ConnectorChannel('/deployment_model_datamodel/channel', '/deployment_model_datamodel/channel');
        sync = mf.zero.io.ModelSynchronizer(model, channel);
        if(isempty(toolboxDetails.Data.source))
            toolboxDetails.Data.source = deployment.ContributorInfo(toolboxDetails.ModelObj);
        end
        if(isempty(toolboxDetails.Data.toolboxId.name))
            toolboxDetails.Data.toolboxId.name = projectObj.Name;
        end
        sync.start();
        
        %Now launch the JS UI
        url = connector.getUrl('/matlab/toolbox/deployment/toolbox/gui/UIContainerExample.html');
        window = matlab.internal.webwindow(url);
      
        % TODO oncleanup object attached to the window?
        
        
        window.Title = 'Toolbox Packaging';
        window.Position(3) = 1200;
        window.Position(4) = 700;
        %window.show;
    end
%end

