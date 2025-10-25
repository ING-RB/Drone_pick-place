function [attrNames, methodsData]=methodsview(qcls, option)
%METHODSVIEW  View the methods for a class.
%   METHODSVIEW(CLASSNAME) displays the methods of a class along with
%   the arguments of each method.  CLASSNAME must be a character vector or
%   string scalar.
%
%   METHODSVIEW(OBJECT) displays the methods of OBJECT's class along
%   with the arguments of each method.
%
%   METHODSVIEW is a visual representation of the information returned
%   by methods -full.
%
%   Example
%     methodsview java.lang.Double;
%
%   See also METHODS, WHAT, WHICH, HELP.

%   Internal use only: option is optional and if present and equal to
%   'noUI' this function returns methods information without displaying
%   the table. Information is returned in two Java String arrays. attrNames
%   is 1-dimensional String array with attribute names and methodsData is
%   2-dimensional String array where each element of the first dimension
%   represents data for one method.
%   If the option is 'libfunctionsview', then the output will be in a
%   libfunctionsview mode, changing "class" to "library" and some
%   formatting

%
%   Copyright 1984-2023 The MathWorks, Inc.

if (nargin < 1)
    error(message('MATLAB:methodsview:nargin'));
end

%% option specified
% defaults
colMask = [1 1 1 1 1 1];
typeString = sprintf('class');
nouiFlag = false;
if nargin > 1
    switch(lower(option))
      case 'noui'
        if nargout ~= 2
            error(message('MATLAB:methodsview:InvalidNumberOfOutputs'));
        end
        nouiFlag = true;
      case 'libfunctionsview'
        colMask = [1 1 1 1 1 0];
        typeString = sprintf('library');
      otherwise
        error(message('MATLAB:methodsview:InvalidInputOption'));
    end
end

%% one input
if nargin == 1 && nargout > 0
    error(message('MATLAB:methodsview:TooManyOutputs'));
end

notChar = ~builtin('ischar', qcls) && ~isStringScalar(qcls);

%% Make sure input is a string or object (MATLAB or opaque).
if notChar && ...
        ~isobject(qcls) &&...
        ~builtin('isa', qcls, 'opaque') ||...
        (builtin('size', qcls, 1) > 1)
    error(message('MATLAB:methodsview:InvalidInput'));
end

clsName = qcls;

%% If input is an object, we can pass straight through to methods without resolving imports
if notChar
    [m,d] = methods(qcls,'-full');
    clsName = builtin('class', qcls);

    %% Otherwise we need to do import resolution
else

    [m,d] = methods(clsName,'-full');
    callers_import = matlab.lang.internal.introspective.callerImports;

    if size(m,1) == 0 && ~isempty(callers_import)
        for i=1:size(callers_import, 1)
            cls = callers_import{i};
            if cls(end) == '*'
                cls = cls(1:end-1);
                cls = [cls clsName]; %#ok<AGROW>
                [m,d] = methods(cls,'-full');
                if size(m,1) > 0
                    break;
                end
            else
                scls = ['.' clsName];
                if size(cls,2) > size(scls,2) && matches(scls, cls(end-size(scls,2)+1:end))
                    [m,d] = methods(cls,'-full');
                    if size(m,1) > 0
                        break;
                    end
                end
            end
        end
    end
end

if ~nouiFlag && size(m,1) == 0
    error(message('MATLAB:methodsview:UnknownClassOrMethod', typeString, clsName, typeString));
end

clear(mfilename);
dflag = 1;
ncols = 6;

if isempty(d)
    dflag = 0;
    d = cell(size(m,1), ncols);
    for i=1:size(m,1)
        t = find(m{i}=='%',1,'last');
        if ~isempty(t)
            d{i,3} = m{i}(1:t-2);
            d{i,6} = m{i}(t+17:end);
        else
            d{i,3} = m{i};
        end
    end
end

%% Reorganize the columns
r = size(m,1);
t = d(:,4);
d(:,4:ncols-1) = d(:,5:ncols);
d(:,ncols) = t;
oldColOne = d(:,1);
d(:,1) = d(:,3);
d(:,3) = d(:,4);
d(:,4) = oldColOne;
[~,x] = sort(d(:,1));
cls = '';
clss = 0;

w = num2cell(zeros(1,ncols));

for i=1:r
    if isempty(cls) && ~isempty(d{i,6})
        t = find(d{i,6}=='.', 1, 'last');
        if ~isempty(t)
            if matches(d{i,1},d{i,6}(t+1:end))
                cls = d{i,6};
                clss = length(cls);
            end
        end
    end
    for j=1:ncols
        if isnumeric(d{i,j})
            d{i,j} = '';
        end
        if j==3 && (d{i,j} == "()")
            d{i,j} = '( )';
        else
            if j==6
                d{i,6} = deblank(d{i,6});
                if clss > 0 && strncmp(d{i,6},cls,clss) &&...
                        (length(d{i,6}) == clss ||...
                         (length(d{i,6}) > clss && d{i,6}(clss+1) == '.'))
                    d{i,6} = '';
                else
                    if ~isempty(d{i,6})
                        t = find(d{i,6}=='.', 1, 'last');
                        if ~isempty(t)
                            d{i,6} = d{i,6}(1:t-1);
                        end
                    end
                end
            end
        end
    end
end

% don't show inheritance value if it's the same as the class name
d(:,6) = erase(d(:,6), clsName);

if ~dflag
    for i=1:r
        d{i,6} = d{i,5};
        d{i,5} = '';
    end
end

%% find the applicable columns, and get the max item length
datacol = zeros(1, ncols);
for i=1:r
    for j=1:ncols
        if ~isempty(d{i,j})
            datacol(j) = 1;
            w{j} = max(w{j},length(d{i,j}));
        end
    end
end

if exist('colMask','var')
    % do not display certain columns
    datacol = datacol .* colMask;
end


%% Calculate the headers
hdridx = find(datacol);
ndatacol = length(hdridx);


%fields from METHOD
hdrs = {getString(message('MATLAB:methodsview:LabelName')),...
        getString(message('MATLAB:methodsview:LabelReturnType')),...
        getString(message('MATLAB:methodsview:LabelArguments')),...
        getString(message('MATLAB:methodsview:LabelQualifiers')),...
        getString(message('MATLAB:methodsview:LabelOther')),...
        getString(message('MATLAB:methodsview:LabelInheritedFrom'))};

% only use the headers for columns that aren't masked out
realHdrs = strings([ndatacol,1]);
for i = 1:ndatacol
    realHdrs(i) = hdrs{hdridx(i)};
end

%% get the data for the non-masked columns, and convert all values to string
realDs = strings([r, ndatacol]);
for i=1:r
    for j=1:ndatacol
        realDs(i,j) = d{x(i),hdridx(j)};
    end
end

%% Return method info if no UI is requested
if (nouiFlag)
    attrNames=realHdrs;
    methodsData=realDs;
    return;
end

%% compute column widths for table
% UITable takes width in pixels, so we use a scale factor to generate
% the correct width.  Scale seems to impact larger columns adversely, so
% we have different scales for different column sizes.  This could
% probably be refined further, but works pretty well.
colWidths = cell(1, ndatacol);
totWidth = 0;
for i=1:ndatacol
    charcnt = max([length(hdrs{hdridx(i)}),w{hdridx(i)}]);
    if charcnt > 40
        scale = 5.5;
    else
        scale = 9;
    end
    colWidths{i} = scale*charcnt;
    totWidth = totWidth+ colWidths{i};
end


%% set number of rows for table.  26 is a somewhat arbitrary number that creates a good sized window
%% with scroll bars if the class has more than 26 methods
numRows = min(r, 26);

%% Create and display the final table
title = makeTitle(clsName);

matlab.internal.methodsViewTable(title, realDs, realHdrs, colWidths, totWidth, numRows);

function title = makeTitle(clsName)
%MAKETITLE subfunction makes an appropriate window header if the input is a
%function or a library
if strncmp(clsName,'lib.',4)
    %is a library
    title = getString(message('MATLAB:methodsview:TitleFunctionsInLibrary', strrep(clsName,'lib.','')));
else
    %is a class
    title = getString(message('MATLAB:methodsview:TitleMethodsForClass', clsName));
end
