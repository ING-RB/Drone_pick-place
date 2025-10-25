classdef (Abstract) TimeArrayDisplay < matlab.mixin.internal.MatrixDisplay
% TIMEARRAYDISPLAY implements DISP and DISPLAY for datetime, duration and calendarDuration.
%
%   Copyright 2014-2024 The MathWorks, Inc.

    methods (Abstract, Access='protected')
        chars = formatAsCharForDisplay(obj);
        fmt = getDisplayFormat(this);
    end

    methods(Access='public',Hidden)
        function disp(obj,objectname)  
            % OBJ - datetime, duration, or calendarDuration array to display.
            % OBJECTNAME - name of the variable for call from display(obj) 

            import matlab.internal.display.lineSpacingCharacter;

            if isempty(obj)
                return;
            elseif (nargin < 2)
                % nargin == 1 => disp(obj)
                % nargin == 2 => display(obj)
                objectname = '';
            end

            sz = size(obj);
            pageSz = sz(1:2);

            if ismatrix(obj)
                displayPage(obj.formatAsCharForDisplay(), pageSz);
                fprintf(lineSpacingCharacter);
            else
                fprintf(lineSpacingCharacter);
                NDsz = [sz(3:end), 1]; %  for ind2sub, ensure NDsz is non-scalar when obj is 3D
                NDsubs = cell(1,ndims(obj)-2);
                for p = 1:prod(NDsz)
                    if (p>1), fprintf(lineSpacingCharacter); end
                    [NDsubs{:}] = ind2sub(NDsz,p);
                    disp([objectname '(:,:' sprintf(',%d',NDsubs{:}) ') =']);
                    fprintf(lineSpacingCharacter);
                    displayPage(subsref(obj,substruct('()',{':',':',p})).formatAsCharForDisplay(), pageSz);
                    fprintf(lineSpacingCharacter);
                end
            end
        end

        function textDisplay = convertObjectToStringForDisplay(objArr, objElemsVisibleToDisplay)
            arguments(Input)
                objArr matlab.mixin.internal.datatypes.TimeArrayDisplay {mustBeNonempty}
                objElemsVisibleToDisplay (:,:) matlab.mixin.internal.datatypes.TimeArrayDisplay {mustBeNonempty} = objArr
            end
            arguments(Output)
                textDisplay (:,:) string
            end
            % Use getDisplayFormat to expand the full array's .fmt property 
            % if it is the default, i.e. "". For datetime, the sub-array 
            % being displayed may happen to have all zero time portion 
            % while elements of other sub-arrays have non-zero time 
            % portion. In that case, applying getDisplayFormat to this one 
            % sub-array would expand "" into a non-time format. Instead, 
            % apply getDisplayFormat to the full array so all sub-arrays 
            % will be displayed with the same format.
            format = getDisplayFormat(objArr);
            textDisplay = string(objElemsVisibleToDisplay, format);
            % Make sure that missing elements are replaced
            % with appropriate keyword
            missingIndices = ismissing(textDisplay);
            textDisplay(missingIndices) = getMissingTextDisplay(objElemsVisibleToDisplay);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Local Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function displayPage(pageChars,pageSz)
% Display one page's worth of data
import matlab.internal.display.lineSpacingCharacter;
maxWidth = matlab.internal.display.commandWindowWidth;
m = pageSz(1); n = pageSz(2);
pad = repmat('   ',m,1);
chars = repmat(' ',m,0);
jold = 1;
for j = 1:n
    colChars = pageChars((1:m)+(j-1)*m,:);
    
    % If we've reached the right margin, display the output built
    % up so far, and then restart for display starting at the left
    % margin.
    if j > 1 && (size(chars,2) + size(pad,2) + size(colChars,2)) > maxWidth
        displayHeader(jold,j-1);
        fprintf(lineSpacingCharacter);
        disp(chars);
        fprintf(lineSpacingCharacter);
        chars = repmat('',m,0);
        jold = j;
    end
    chars = [chars pad colChars]; %#ok<AGROW>
end
if jold > 1
    displayHeader(jold,j);
    fprintf(lineSpacingCharacter);
end
disp(chars);
end

function displayHeader(fromCol,toCol)
if fromCol == toCol
    header = getString(message('MATLAB:datetime:uistrings:DisplayColumnHeaderShort',fromCol));
else
    header = getString(message('MATLAB:datetime:uistrings:DisplayColumnHeader',fromCol,toCol));
end
disp(header);
end
