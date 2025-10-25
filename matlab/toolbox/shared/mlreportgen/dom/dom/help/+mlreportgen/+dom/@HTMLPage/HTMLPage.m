%mlreportgen.dom.HTMLPage Create an HTML page for a multipage HTML document
%     pageObj = HTMLPage() creates an empty HTMLPage object that generates
%     an HTML file with an auto-generated file name (see FileName
%     property). Use the FileName property to specify the custom name of
%     the HTML file that it generates. Use its append() method to add
%     content to the HTML page. When added to a DOM Document of type
%     html-multipage, it generates an HTML file, which corresponds to a
%     single page of the multipage HTML report.
%
%     pageObj = HTMLPage(fileName) creates an empty HTMLPage object, that
%     generates an HTML file with the specified fileName. Use its append()
%     method to add content to the page.
%
%     pageObj = HTMLPage(fileName,templatePath) creates an empty HTMLPage
%     object, that generates an HTML file with the specified fileName and
%     based on the custom template specified by the templatePath. Use its
%     append() method to add content to the page.
%
%     pageObj = HTMLPage(fileName,domObj) creates an HTMLPage object, that
%     generates an HTML file with the specified fileName and with the
%     specified domObj as the page content. Use its append() method to add
%     more content to the page.
%
%    HTMLPage methods:
%        append         - Append content to this HTML page
%
%    HTMLPage properties:
%        FileName       - HTML page file name
%        TemplatePath   - HTML page template path
%        Parent         - Parent of this HTML page
%        Children       - Children of this HTML page
%        Tag            - Tag of this HTML page
%        Id             - Id of this HTML page
%
%    Note: HTMLPage can only be added to a DOM Document of type
%    HTML-MULTIPAGE.
%
%    Example:
%
%        % Import the DOM API package
%        import mlreportgen.dom.*
%
%        % Create a multipage HTML document
%        d = Document("myreport","html-multipage");
%        open(d);
%
%        % Create the first HTML page with an image
%        page1 = HTMLPage();
%        append(page1,Heading1("Chapter 1. Image"));
%        img = Image(which("ngc6543a.jpg"));
%        img.Height = "4in";
%        img.Width = "4in";
%        append(page1,img);
%        append(d,page1);
%
%        % Create the second HTML page with a table
%        page2 = HTMLPage();
%        append(page2,Heading1("Chapter 2. Table"));
%        tbl = Table(magic(5));
%        tbl.Border = "solid";
%        tbl.RowSep = "solid";
%        tbl.ColSep = "solid";
%        tbl.Width = "100%";
%        append(page2,tbl);
%        append(d,page2);
%
%        % Create the third HTML page with a nested list
%        page3 = HTMLPage();
%        append(page3,Heading1("Chapter 3. List"));
%        append(page3,UnorderedList({"a", "b", "c", {1,2,3}, "d"}));
%        append(d,page3);
%
%        % Close and view the report
%        close(d);
%        rptview(d);
%
%    See also mlreportgen.dom.Document.Type

%    Copyright 2023 The MathWorks, Inc.
%    Built-in class

%{
properties
     %FileName HTML page file name
     %    Name of the generated HTML file, specified as a character vector
     %    or a string scalar. If the file name does not specify an
     %    extension, ".html" is used as the extension for the generated
     %    HTML file. If the file name specifies an extension, it must be
     %    ".html". If any extension other than ".html" is specified, an
     %    error is thrown. The generated HTML file represents a single page
     %    of the multipage HTML report. If this property is not specified,
     %    the DOM API auto-generates the file name with the syntax
     %    "documentName_pageNumber.html". For e.g., if the multipage HTML
     %    Document name is specified as "myreport", the second page of this
     %    report is named as "myreport_2.html", the third page is named as
     %    "myreport_3.html", and so on. The first page in the report is
     %    always named as "root.html".
     FileName;

     %TemplatePath HTML page template path
     %    Path of this page's template specified as a character vector or
     %    string scalar. By default, this property specifies the path of
     %    the default multipage HTML template "default_multipage.htmtx",
     %    whose body contains 3 holes:
     %        NavBarTop     - Hole to include the navigation bar at the top
     %                        the page
     %        Content       - Hole to include the page content
     %        NavBarBottom  - Hole to include the navigation bar at the
     %                        bottom of the page
     TemplatePath;
end
%}