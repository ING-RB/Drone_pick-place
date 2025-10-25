function privquatdisp(a,b,c,d, name)
% PRIVQUATDISP - display quaternion values based on parts
%   This function is for internal use only. It may be removed in the future.

%   Copyright 2017 The MathWorks, Inc.

% Here a page means all elements for a given row, column pair. For
% multidimensional arrays there are many pages. MATLAB disps them in turn
% with headers (:,:,1) , ...(:,:,4) , for example.
% 
% Approach: 
% Iterate through all elements. Get the disp string for each element part
% (a,b,c,d) for each element on each page. Store them in the pages
% variable.
% Build a disp string for each page header along the way. Store in headers
% variable.
% Also compute the sign for each part of each element. Store in signs
% variable.
% To make all the columns the same width, pad() the pages variable prior to
% outputting to the command window.
% Concatenate the signs to pages and then output with the headers.
%
% Note: Column wrapping is not supported. There are not facilities in
% MATLAB to aid in this.
% 
% Note headers, pages, and signs use 4d arrays. They are 4(quaternion parts) x rows x cols x screen pages

%Get the size of the matrix

if isempty(a)
    return; %empty object
end

q = {a,b,c,d};


[szc{1:ndims(a)}] = size(a);
sz = [szc{:}];  %An array of all the matrix dimensions.

pagesz = sz(3:end); %Header disp is always (:,:, ... ) so we only need last N-2
numpages = prod(pagesz);    %How many pages to display at command window

%Build a cnt cell array which we use to iterate through the pages. This will get incremented
%as the header variables should.
%
cntvec = ones(1,numel(pagesz));
cnt = num2cell(cntvec);
cntorig = cnt;
doheader = ~ismatrix(a); %Do we need headers?

%Format loose or compact. This is the MATLAB format command?
isLoose = strcmp(matlab.internal.display.formatSpacing,'loose');
if isLoose
    looseline = '\n';
else
    looseline = '';
end

fmt = matlabshared.rotations.internal.getFloatFormat(class(a)); %Taken from disp of table
pages = strings(4, size(a,1), size(a,2),max( numpages,1));
signs = strings(4, size(a,1), size(a,2),max( numpages,1));

headers = cell(1,max(numpages,1)); %at least one page

%iterate through to get all pages to build the headers, signs and pages vars.
%There is at least 1 page so, one is outside the for loop since bumpcount is first.
[headers{1}, signs(:,:,:,1),pages(:,:,:,1)] = getparts(q,cnt,doheader,fmt); 
for ii=2:numpages
   cnt = bumpcount(cnt, pagesz);
    [headers{ii}, signs(:,:,:,ii),pages(:,:,:,ii)] = getparts(q,cnt,doheader,fmt); 
end

for ii=1:numpages
    headers{ii} = name + headers{ii};
end

%Now we have all the variables. Make columns the same width. 
%pad all the pages
ps = pad(pages, 'left');

%Start over for disping
cnt =cntorig;

%display. Same iteration loop style.
printpage(headers{1}, signs(:,:,:,1), ps(:,:,:,1), looseline, doheader);
for ii=2:numpages
    cnt = bumpcount(cnt, pagesz);
    printpage(headers{ii}, signs(:,:,:,ii), ps(:,:,:,ii), looseline, doheader);  
end
end

function cnt = bumpcount(cnt, sz)
    %Increment the cnt header each time through the loop above.
    idx = find([cnt{:}] < sz, 1, 'first');
    cnt{idx} = cnt{idx} + 1;
    if idx > 1
        cnt(1:idx-1) = {1};
    end
end

function [header, signs, page] = getparts(q, cnt, doheader, fmt)
    %Get the header, signs and page variables for the page index=cnt.
    header = getheader(cnt,doheader);
    [signs, page] = getpage(q,cnt,fmt);
end

function h = getheader(cnt, doheader)
    %Build the header struct. If doheader=false, return string('');
    h = '';
    if doheader
        h = sprintf('(:,:');
        for ii=1:numel(cnt)
            h = [h, sprintf(',%d', cnt{ii})];
        end
        h = [h sprintf([') = \n'])];
    end
    h = string(h);
end
function [signs, pages]= getpage(q,cnt, fmt)
    %Get all the signs and pages variables for the quaternion q at matrix
    %page cnt. fmt is the format string.
%    page = q(:,:,cnt{:});
%    a = page.a;
%    b = page.b;
%    c = page.c;
%    d = page.d;

    a = q{1}(:,:,cnt{:});
    b = q{2}(:,:,cnt{:});
    c = q{3}(:,:,cnt{:});
    d = q{4}(:,:,cnt{:});


    pages= strings(4,size(a,1), size(a,2));
    signs =strings(4,size(a,1), size(a,2));
    for rr=1:size(a,1)
        for cc=1:size(a,2)
            [signs(:,rr,cc), pages(:,rr,cc)] = quatstr(a(rr,cc), b(rr,cc), c(rr,cc), d(rr,cc),fmt);
        end
    end
  
end
function  printpage(h,sgn,p, looseline, doheader)
    %Actual disp output code. Combine the header h, signs sgn and page p.
    fprintf(looseline);
    if doheader
        fprintf(h);
        fprintf(looseline);
    end
    comb = shiftdim(join(sgn+p,'',1), 1); %after joining, delete that dim.
    disp(join(join(comb,'',2),char(10)));
    fprintf(looseline);    
end

function [signs,qs] = quatstr(a,b,c,d,fmt) %#ok<INUSL>
    %Get the signs and page variables for the 4 parts of a single element
    qs = strings(1,4);
    qs(1) = strtrim(string(num2str(a,fmt)));
    qs(2) = strtrim(string(num2str(abs(b),fmt))) + 'i';
    qs(3) = strtrim(string(num2str(abs(c),fmt))) + 'j';
    qs(4) = strtrim(string(num2str(abs(d),fmt))) + 'k';

    cplx = [b c d];

    csign = cplx < 0;

    signs(csign) = string(' - ');
    signs(~csign) = string(' + ');
    signs = [string('    ') signs];
end


