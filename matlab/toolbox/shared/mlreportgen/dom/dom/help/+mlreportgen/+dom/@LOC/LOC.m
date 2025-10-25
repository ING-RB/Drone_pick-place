%mlreportgen.dom.LOC Creates a list of captions with hyperlinks 
%    loc = LOC() creates a list containing the contents of paragraphs 
%    sequence that contain autonumbers with a specified stream name. 
%    The DOM API provides objects for creating lists of figures   
%    (mlreportgen.dom.LOF) and lists of tables (mlreportgen.dom.LOT).  
%    You can use instances of this class to create lists of other types of  
%    objects in a report, for example, a list of equations or a list of authorities.
%    To do this, your report program should append this object to the point 
%    in report where you want the list to appear. The object should specify 
%    an autonumber stream name. Then your program must create a paragraph in 
%    front of each item to be listed. The paragraph should specify a caption 
%    or title for the item and an autonumber having the specified name.
%
%    loc = LOC(autoNumberStreamName) creates  a list of captions 
%    with the specified AutoNumberStreamName.
%
%    LOC methods:
%        clone              - Clone this LOC object
%
%    LOC properties:
%        AutoNumberStreamName - Name of numbering stream
%        LeaderPattern        - Leader pattern
%        StyleName            - Name of LOC object's style sheet-defined style
%        Style                - Formats that defines this LOC object's style
%        CustomAttributes     - Custom element attributes
%        Children             - Children of this LOC object
%        Parent               - Parent of this LOC object
%        Tag                  - Tag of this LOC object
%        Id                   - Id for this LOC object

%    Example
%     import mlreportgen.dom.*
% 
%     rpt = Document('Report with a List From Custom Caption', "pdf");
%     %rpt = Document('Report with a List From Custom Caption', "docx");
%     %rpt = Document('Report with a List From Custom Caption', "html");
%     %rpt = Document('Report with a List From Custom Caption', "html-file");
% 
%     loc = LOC;
%     loc.AutoNumberStreamName = "equation";
%     append(rpt,loc);
%     append(rpt, PageBreak);
% 
%     p = Paragraph('E = mc2');
%     append(rpt,p);
% 
%     p = Paragraph('Equation ');
%     p.Style = {CounterInc('equation'),WhiteSpace('preserve')};
%     append(p,AutoNumber('equation'));
%     append(p, ' Mass–energy equivalence');
%     append(rpt,p);
% 
%     close(rpt);
%     rptview(rpt);

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties

     %AutoNumberStreamName Name of numbering stream
     %    This property specifies the name of numbering stream based on which 
     %    the links and caption are generated.
     AutoNumberStreamName;

     %LeaderPattern Leader pattern
     %    This property specifies the type of leader to use between the link 
     %    caption and page number.
     %
     %    Valid values are:
     %
     %    Value               DESCRIPTION
     %    'dots' or '.'       leader of dots
     %    'space' or ' '      leader of spaces
     LeaderPattern;

end
%}