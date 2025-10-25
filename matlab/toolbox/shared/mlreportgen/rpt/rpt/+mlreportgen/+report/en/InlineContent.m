classdef InlineContent< mlreportgen.report.HoleReporter
%INLINECONTENT Reporter for templates with one inline Content hole
%    Reporters use instances of this class to fill inline holes in
%    their templates. You do not need to create instances yourself.
%
%    Reporters have methods that return instances of this object to
%    give you an opportunity to customize the format of the content
%    used to fill the holes in their templates. For example, the
%    TitlePage reporter's getTitleReporter method returns the instance
%    of this object that the TitlePage reporter uses to fill the
%    TitlePageTitle hole in its template. You can customize the title
%    format by specifying a custom template for the InlineContent
%    reporter returned by the getTitleReporter method.
%
%    InlineContent properties:
%      HoleId         - Name of hole to be filled by this reporter
%      Content        - Content of hole to be filled by this reporter
%      TemplateSrc    - InlineContent reporter's template source
%      TemplateName   - Template name
%      LinkTarget     - Hyperlink target for this reporter
%
%    See also mlreportgen.report.TitlePage.getTitleReporter

     
    %    Copyright 2017-2018 The MathWorks, Inc.

    methods
    end
    properties
        % Content Content of hole to be filled by this reporter
        %    Specifies the content of the hole to be filled by this
        %    reporter. You can use any of the following to specify the
        %    hole content
        %
        %        - MATLAB string
        %        - character array
        %        - DOM object
        %        - 1xN or Nx1 array of strings or DOM objects
        %        - 1xN or Nx1 cell array of strings, character arrays,
        %          and/or DOM objects
        Content;

    end
end
