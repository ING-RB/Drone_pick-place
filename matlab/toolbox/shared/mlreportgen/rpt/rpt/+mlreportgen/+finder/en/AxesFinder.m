classdef AxesFinder< mlreportgen.finder.Finder
%mlreportgen.finder.AxesFinder Find axes in a figure
%   finder = AxesFinder(figure) creates a finder that finds axes
%   in a figure, specified as a figure handle or path to a figure file.
%   Use the finder's find method to perform the search.
%
%   finder = AxesFinder(p1=v1,p2=v2,...) creates an
%   axes finder and sets its properties (p1, p2, ...) to the
%   specified values (v1, v2, ...).
%
%
%   AxesFinder properties:
%
%       Container                   - Figure to search for axes
%       Properties                  - Properties of axes to find
%
%   AxesFinder methods:
%
%       find    - Finds axes in specified container
%       hasNext - Determines whether the queue has a result
%       next    - Returns the next axes in the axes result queue
%
%   Example:
%
%         
%         import mlreportgen.report.*
%         import mlreportgen.finder.*
%
%         % Create a MATLAB Report
%         rpt = Report("AxesFinder Example","pdf");
%          
%         % Create a figure
%         f = figure;
%          
%         % Create two axes
%         axes1 = subplot(2,1,1);
%         x = linspace(0,10);
%         y1 = sin(x);
%         plot(x,y1);
%          
%         axes2 = subplot(2,1,2);
%         y2 = sin(5*x);
%         plot(x,y2);
%          
%         % Find axes in the figure using AxesFinder
%         result = find(AxesFinder(f));
%         
%         % Append the result to the report
%         append(rpt,result);
%
%         % Close the report and open the viewer
%         close(rpt);
%         rptview(rpt);     
%
%   See also mlreportgen.report.Axes, mlreportgen.finder.AxesResult

     
    %   Copyright 2021-2024 The MathWorks, Inc.

    methods
        function out=AxesFinder
        end

        function out=emptyResult(~) %#ok<STOUT>
        end

        function out=findImpl(~) %#ok<STOUT>
            %findImpl Populates the NodeList property of this finder with
            % AxesResult objects for axes used by Container. Also
            % sets the NodeCount property.
        end

    end
end
