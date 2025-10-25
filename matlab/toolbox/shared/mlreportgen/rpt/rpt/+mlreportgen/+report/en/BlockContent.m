classdef BlockContent< mlreportgen.report.HoleReporter
%BLOCKCONTENT Reporter for templates with one block Content hole
%    Reporters use instances of this class to fill block holes in
%    their templates. You do not need to create instances yourself.
%
%    Reporters have methods that return instances of this object to
%    give you an opportunity to customize the format of the content
%    used to fill the holes in their templates. For example, the
%    BaseTable reporter's getContentReporter method returns the
%    instance of this object that the BaseTable reporter uses to fill
%    the Content hole in its template. You can customize the content
%    format by specifying a custom template for the BlockContent
%    reporter returned by the getContentReporter method.
%
%    BlockContent properties:
%      HoleId         - Name of hole to be filled by this reporter
%      Content        - Content of hole to be filled by this reporter
%      TemplateSrc    - BlockContent reporter's template source
%      TemplateName   - Template name
%      LinkTarget     - Hyperlink target for this reporter
%
%    See also mlreportgen.report.BaseTable.getContentReporter

     
    %   Copyright 2017-2018 The MathWorks, Inc.

    methods
    end
    properties
        % Content Content of hole to be filled by this reporter
        %    Specifies the content of the hole to be filled by this
        %    reporter.
        Content;

    end
end
