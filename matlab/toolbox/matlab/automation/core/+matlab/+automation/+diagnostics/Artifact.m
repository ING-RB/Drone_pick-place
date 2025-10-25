classdef(Hidden, AllowedSubclasses={?matlab.automation.diagnostics.FileArtifact}) ...
        Artifact < handle & matlab.mixin.Heterogeneous
    % This class is undocumented and may change in a future release.
    
    % Artifact - Fundamental interface for artifacts
    %
    %   Artifact properties:
    %       Name     - The name of the artifact
    %       Location - The parent folder where the artifact is located
    %       FullPath - The full path of the artifact
    %
    %   Artifact methods:
    %       copyTo - Copy artifacts to a new location
    
    %  Copyright 2016-2024 The MathWorks, Inc.

    properties(SetAccess=immutable)
        % Name - The name of the artifact
        %
        %   The Name property is the name of the artifact as a string scalar. For
        %   example, if the full path of a file artifact is "C:\Hello\World.txt",
        %   the value of Name would be "World.txt".
        Name string
    end

    properties(SetAccess=private)       
        % Location - The parent folder where the artifact is located
        %
        %   The Location property is the parent folder where the artifact is
        %   located as a string scalar. For example, if the full path of a file
        %   artifact is "C:\Hello\World.txt", the value of Location would be
        %   "C:\Hello".
        Location string
    end
    
    properties(Dependent, SetAccess=immutable)
        % FullPath - The full path of the artifact
        %
        %   The FullPath property is the full path of the artifact as a
        %   string scalar. For any given artifact, the artifact.FullPath
        %   value is equal to artifact.Location + filesep + artifact.Name.
        FullPath string
    end

    properties (Hidden)
        % FinalLocation - The parent folder where the artifact will finally be moved to.
        %
        %   The FinalLocation is the parent folder where the artifact is
        %   is finally moved to.

        FinalLocation;
    end
    
    methods(Access=protected)
        function artifact = Artifact(fileLocation,fileName, options)
            arguments
                fileLocation
                fileName
                options.FinalLocation = fileLocation;
            end

            artifact.Name = fileName;
            artifact.Location = fileLocation;
            artifact.FinalLocation = options.FinalLocation;
        end
    end
       
    methods
        function value = get.FullPath(artifact)
            value = artifact.Location + filesep + artifact.Name;
        end
    end
    
    methods(Sealed)
        function newArtifacts = copyTo(artifacts, newLocation)
            % copyTo - Copy artifacts to a new location
            %
            %   newArtifacts = copyTo(artifacts, newLocation) copies the
            %   provided artifacts to a new folder location and returns an
            %   array of matlab.automation.diagnostics.Artifact instances of
            %   the same size. The Location property on each instance of
            %   newArtifacts is set to newLocation.
            %
            %   Example:
            %       import matlab.automation.diagnostics.FileArtifact
            %       fileArtifact1 = FileArtifact('someFile.mat');
            %       fileArtifact2 = FileArtifact('anotherFile.m');
            %       artifacts = [fileArtifact1,fileArtifact2];
            %       newLocation = tempdir();
            %       newArtifacts = artifacts.copyTo(newLocation);
            
            import matlab.automation.diagnostics.Artifact;
            newLocation = matlab.automation.internal.folderResolver(newLocation);
            newLocation = string(newLocation);
            newArtifactsCell = arrayfun(@(x) x.copyArtifactTo(newLocation),...
                artifacts,'UniformOutput',false);
            newArtifacts = [Artifact.empty(1,0), newArtifactsCell{:}];
        end
    end
    
    methods(Abstract, Hidden, Access=protected)
        newScalarArtifact = copyArtifactTo(scalarArtifact,newLocation)
    end

    methods (Hidden, Static)
        function artifact = loadobj(artifact)
            % Update the Location property to reflect the FinalLocation
            % where the artifact will be moved. This is particularly
            % important for parallel test sessions run on remote workers.
            artifact.Location = artifact.FinalLocation;
        end
    end
end
