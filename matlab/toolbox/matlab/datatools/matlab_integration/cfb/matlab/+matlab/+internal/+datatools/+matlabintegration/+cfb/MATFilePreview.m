classdef MATFilePreview < handle
    % MATFilePreview
    % Creates a custom workspace for a given MATFile
    % Creates a UIWorkspaceBrowser for the same

    % Copyright 2022-2025 The MathWorks, Inc.


    properties (Access = public)
        Workspace matlab.internal.datatools.matlabintegration.cfb.MATFileWorkspace
        WorkspaceBrowser internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowserManager
        WorkspaceKey = ''
        Namespace char
        Context char = 'MATFileCFBPreview';
        MatFileName char
    end

    properties (Access = protected)
        DeleteListener
    end

    methods
        function this = MATFilePreview(namespaceChannel, matFileName)
            if(~isempty(matFileName))
                this.MatFileName = matFileName;
            end
            if(~isempty(namespaceChannel))
                this.Namespace = namespaceChannel;
            end
            this.WorkspaceKey = this.createMATFileWorkspaceBrowser();
        end


        % Creates Workspace using MATFileWorkspace
        % Starts up the server-side of UIWorkspace browser by calling into
        % createWorkspaceBrowser of MF0ViewModelWorkspaceBrowserFactory
        function workspaceKey = createMATFileWorkspaceBrowser(this)
            workspaceKey = '';
            import internal.matlab.desktop_workspacebrowser.MF0ViewModelWorkspaceBrowserFactory;
            try
            if(~isempty(this.MatFileName))
                this.Workspace = matlab.internal.datatools.matlabintegration.cfb.MATFileWorkspace(this.MatFileName);
                this.WorkspaceBrowser = MF0ViewModelWorkspaceBrowserFactory.createWorkspaceBrowser(this.Workspace, this.Namespace, this.Context, true);
                workspaceKey = this.WorkspaceBrowser.WorkspaceKey;
                % We do not need Class and Size columns for tooltip light
                % view
                this.WorkspaceBrowser.Documents.ViewModel.setColumnVisible('Class', false);
                this.WorkspaceBrowser.Documents.ViewModel.setColumnVisible('Size', false);

                % Need to add a delete listener to clean up the workspace,
                % otherwise the workspace will be deleted too soon because
                % this instance disapears after the createPreview method is
                % closed, we need to tie it's deletion to the manager
                % instead
                this.DeleteListener = addlistener(this.WorkspaceBrowser, "ObjectBeingDestroyed", @(e,d)this.deleteWorkspace);
            end
            catch e
                internal.matlab.datatoolsservices.logDebug("wsb","MATFilePreview::createMATFileWorkspaceBrowser: " + e.message);
            end
        end

        % Clean up to delete the create workspace
        function delete(this)
            if ~isempty(this.DeleteListener) && isvalid(this.DeleteListener)
                delete(this.DeleteListener);
            end
        end

    end

    methods (Access = protected)
        function deleteWorkspace(this)
            delete(this.Workspace);
        end
    end

    methods(Static)
        function workspaceKey = createPreview(namespaceChannel, filePath)
            internal.matlab.datatoolsservices.logDebug("WSB::MATFilePreview::createPreview", "Creating preview: " + namespaceChannel + "  for file: " + filePath);

			% Startup the Workspace Browser backend so it is ready to handle drops
            internal.matlab.datatoolsservices.executeCmd("[~] = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance;");

            % Calls the constructor by passing down the arguments
            mfp = matlab.internal.datatools.matlabintegration.cfb.MATFilePreview(namespaceChannel, filePath);
            workspaceKey = mfp.WorkspaceKey;
            internal.matlab.datatoolsservices.logDebug("WSB::MATFilePreview::createPreview", "Preview Created with key: " + workspaceKey)
        end

        function destroyAllPreviews(currentOffset)
            % Kills all current instances of the MATFilePreviews with keys
            % less than currentOffset.  If currentOffset is not passed in
            % all MATFilePreviews are killed
            % g2915732
            arguments
                currentOffset (1,1) double = 0
            end
            internal.matlab.datatoolsservices.logDebug("WSB::MATFilePreview::DestroyAll", "destroyAllPreviews < " + currentOffset);

            wsbManagers = internal.matlab.desktop_workspacebrowser.WSBFactory.getWorkspaceBrowserInstances();
            keys = wsbManagers.keys;
            for i=1:length(keys)
                key = keys{i};
                matchedKey = regexp(key, "(?<baseKey>\/MATFileCFBPreviewWorkspaceChannel\/)(?<fn>.*?)(?<offset>\d+)", "names");
                if ~isempty(matchedKey)
                    offset = str2double(matchedKey.offset);
                    if currentOffset == 0 || offset < currentOffset
                        internal.matlab.datatoolsservices.logDebug("WSB::MATFilePreview::DestroyAll", "Destroying preview " + key);
                        delete(wsbManagers(key));
                    else
                        internal.matlab.datatoolsservices.logDebug("WSB::MATFilePreview::DestroyAll", "Skipping preview " + key);
                    end
                end
            end
        end
    end
end
