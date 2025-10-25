function celldisp(c,s)
%CELLDISP Display cell array contents.
%   CELLDISP(C) recursively displays the contents of a cell array.
%
%   CELLDISP(C,NAME) uses the character vector NAME for the display instead
%   of the name of the first input (or 'ans').
%
%   See also CELLPLOT.

%   Copyright 1984-2021 The MathWorks, Inc.

narginchk(1,2);
if ~iscell(c)
  error(message('MATLAB:celldisp:notCellArray'));
end

if nargin==1
    s = inputname(1);
else
    % Check variable name
    validateVariableName(s);

    % Convert input to char
    s = convertStringsToChars(s);   
end

if isempty(s)
    s = 'ans';
end

isloose = (matlab.internal.display.formatSpacing == "loose");

for i=1:numel(c)
  if iscell(c{i}) && ~isempty(c{i})
     celldisp(c{i},[s subs(i,size(c))])
  else
    if isloose, disp(' '), end
    disp([s subs(i,size(c)) ' ='])
    if isloose, disp(' '), end
    if ~isempty(c{i})
      disp(c{i})
    elseif ismatrix(c{i})
      if iscell(c{i})
        disp('     {}')
      elseif ischar(c{i})
        disp('     ''''')
      elseif isnumeric(c{i})
        disp('     []')
      else
        display(c{i});
      end
    else
        display(c{i});
    end
    if isloose, disp(' '), end
  end
end
end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s = subs(i,siz)
%SUBS Display subscripts

if length(siz)==2 && any(any(siz==1))
  v = cell(1,1);
else
  v = cell(size(siz));
end
[v{1:end}] = ind2sub(siz,i);

s = ['{' int2str(v{1})];
for i=2:length(v)
  s = [s ',' int2str(v{i})];
end
s = [s '}'];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function isScalarValidString(inp)
    % Input must be a scalar string and it must not be a missing string
    if ~isStringScalar(inp)
        error(message('MATLAB:string:MustBeStringScalarOrCharacterVector'));
    elseif ismissing(inp)
        error(message('MATLAB:string:MissingNotSupported'));
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function validateVariableName(inp)
    % Input must be a scalar sting or char row vector
    if isstring(inp)
        isScalarValidString(inp);
    elseif ~ischar(inp)
        error(message('MATLAB:string:MustBeStringScalarOrCharacterVector'));
    end
end
