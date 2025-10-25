classdef Finder< matlab.mixin.SetGet
%FINDER Abstract finder class
%   Class of finders that can be used to find result objects that can be
%   added to a mlreportgen.report.Report object.

 
    %   Copyright 2017-2024 The MathWorks, Inc.

    methods
        function out=Finder
        end

        function out=emptyResult(~) %#ok<STOUT>
        end

        function out=find(~) %#ok<STOUT>
            %find Find results based on finder specifications
            % results = find(finder) Searches the specified Container for
            %   finder results. This method returns result objects that
            %   represent the objects found by this finder. You can add the
            %   result objects to the report directly or add them to a
            %   reporter that you then add to a report.
            %
            %   See also mlreportgen.finder.Result
        end

        function out=findImpl(~) %#ok<STOUT>
        end

        function out=hasNext(~) %#ok<STOUT>
            %hasNext Whether the queue has a result
            %  tf = hasNext(finder) determines if the container to be
            %  searched by finder has at least one result that meets the
            %  requirements set by the finder's options. If so, it queues
            %  that result as the next result to be returned by the
            %  finder's next method. Use the finder's next method to obtain
            %  that result. On subsequent invocations, this method
            %  determines if the container has a result that has not yet
            %  been retrieved by the next method. If so, this method queues
            %  the result as the next result to be retrieved by the next
            %  method and returns true. If the result queue is empty, this
            %  method returns false. Use this method with the finder's next
            %  method in a while loop to progressively search a container.
            %
            %  Note
            %
            %  You can use either find or hasNext and next to search a
            %  container as a matter of preference. Neither has a
            %  performance advantage over the other.
            %
            %  See also mlreportgen.finder.Finder.next,
            %  mlreportgen.finder.Finder.find
        end

        function out=isIterating(~) %#ok<STOUT>
            %isIterating Return true if search queue exists
            %   tf = isIterating(finder) returns true if a valid
            %   search result queue exists in the finder.
        end

        function out=mustNotBeIterating(~) %#ok<STOUT>
        end

        function out=next(~) %#ok<STOUT>
            %next Get next search result in the result queue
            %   result = next(finder) returns the next search result in the
            %   result queue created by the finder's hasNext method. You
            %   can add information about the result to a report by adding
            %   the result objects to the report directly or by adding them
            %   to a reporter that you then add to a report.
            %
            %   See also mlreportgen.finder.Result
        end

        function out=reset(~) %#ok<STOUT>
            %reset Resets the finder's search queue
            %   reset(finder) initializes the finder's search
            %   queue variables.
        end

        function out=satisfyObjectPropertiesConstraint(~) %#ok<STOUT>
        end

    end
    properties
        % Container Container to be searched
        %   Container to be searched by this finder.
        Container;

        %NextNodeIndex Index of next node in search results queue
        NextNodeIndex;

        %NodeCount Number of results in NodeList
        NodeCount;

        %NodeList List of axes results
        NodeList;

        % Properties Properties of objects to be found
        %   The value of this property must be a cell array of name-value
        %   pairs that specify the properties of objects to be found by
        %   this finder. The finder returns only objects that have the
        %   specified properties with the specified values.
        %
        %   Example:
        %     % When using the AxesFinder, the below example demonstrates
        %     % how to use its "Properties" property to specify the
        %     % properties of the axes to be found. You can use this
        %     % property in the similar way for other finder classes.
        %
        %     % Create a figure with two axes
        %     f = figure;
        %     
        %     axes1 = subplot(2,1,1);
        %     x = linspace(0,10);
        %     y1 = sin(x);
        %     plot(x,y1);
        %     
        %     axes2 = subplot(2,1,2);
        %     y2 = sin(5*x);
        %     axes2.Units = 'inches';
        %     plot(x,y2);
        %     
        %     % Create an axes finder
        %     finder = mlreportgen.finder.AxesFinder(f);
        %
        %     % Find axes with Units 'normalized'
        %     finder.Properties = {'Units', 'normalized'};
        %     results = find(finder);
        Properties;

    end
end
