classdef ReporterLinkResolver< handle
% ReporterLinkResolver returns a link to a report for an object if the
% report already exists.

 
% Copyright 2018-2023 The MathWorks, Inc.

    methods
        function out=ReporterLinkResolver
        end

        function out=clear(~) %#ok<STOUT>
            % Clears the link map for any existing entry
        end

        function out=getLink(~) %#ok<STOUT>
            % Returns DOM InternalLink object from the map for the
            % specified object, if it exist in the map
        end

        function out=instance(~) %#ok<STOUT>
            % instance = instance() Static method to return the persistent
            % reporter link resolver object.
        end

        function out=putLink(~) %#ok<STOUT>
            % Adds the specified object and its corresponding DOM
            % InternalLink object to the map
        end

    end
    properties
        % Map to store the DOM InternalLink object for any variable value
        % object
        LinkMap;

    end
end
