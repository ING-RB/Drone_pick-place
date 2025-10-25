classdef Information< dynamicprops
%INFORMATION Project wide information
%   A collection of information about the project.

 
%   Copyright 2015-2022 The MathWorks, Inc.

    methods
    end
    properties
        % The project description
        Description;

        Project;

        % Logical stating whether this project is read only
        ReadOnly;

        % The source control repository location
        RepositoryLocation;

        % The name of the Source Control Integration
        SourceControlIntegration;

        % Custom information from the source control adapter
        SourceControlMessages;

        % Is the project loaded as a top level project
        TopLevel;

    end
end
