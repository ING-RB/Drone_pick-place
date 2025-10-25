function header = getHeader(input, headerLinkAttributes)  
% getHeader returns the header for a given type
% Inputs - 
%       input - the variable for which the header needs to be computed
%          Inputs have to be one of the following types:
%          * struct
%          * function_handle
%          * double
%          * single
%          * int8
%          * uint8
%          * int16
%          * uint16
%          * int32
%          * uint32
%          * int64
%          * uint64
%          * logical
%          * cell
%          * char
%          * matlab.mixin.internal.MatrixDisplay
%          * string
%          * MATLAB enumerations
%          * MATLAB objects
%       headerLinkAttributes - attributes to be added to the <a> tag 
%       of the header. For example 'class="headerDataType"'. If  second 
%       argument does not exist, default attribute 
%       'style="font-weight:bold"' will be added to the <a> tag which is 
%       used by command window. 
% Output - The header

% Copyright 2016-2024 The MathWorks, Inc.

if nargin == 1
    headerLinkAttributes = 'style="font-weight:bold"';
end

switch (class(input))
    case 'struct'
        header = getStructHeader(input, headerLinkAttributes);
    case 'function_handle'
        header = getFunctionHandleHeader(input, headerLinkAttributes);   
    case 'double'
        header = getDoubleHeader(input, headerLinkAttributes);
    case {'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64','single'}
        header = getHeaderForNumericClasses(input, headerLinkAttributes);
    case 'char'
        header = getHeaderForChar(input, headerLinkAttributes);
    case 'cell'
        header = getHeaderForCellArrayTypes(input, headerLinkAttributes);
    case 'logical'
        header = getHeaderForLogicalTypes(input, headerLinkAttributes);
    otherwise
      if isa(input,'tabular')
          header = getTabularHeader(input, headerLinkAttributes);
      elseif isenum(input)
          header = getHeaderForEnum(input, headerLinkAttributes);
      elseif isobject(input)
          mc = metaclass(input);
          hasDispImpl = findobj(mc.MethodList, 'Name', 'disp');
          if isa(input, 'matlab.mixin.internal.MatrixDisplay') || ...
              isempty(hasDispImpl) || ~strcmp(hasDispImpl.DefiningClass.Name, class(input))
              headerWithEndOfLine = matlab.internal.display.getObjectHeaderHelper(input);
              temp = strsplit(headerWithEndOfLine, newline);
              header = temp{1};
              % g1983668
              % For objects, replace the default header link
              % attributes (i.e. 'style="font-weight:bold"') with the ones 
              % provided as input
              if nargin > 1
                header = replace(header, 'style="font-weight:bold"', headerLinkAttributes);
              end
          else
              header = '';
          end
      else
          header = '';
      end
end
end

function out = getStructHeader(inp, headerLinkAttributes)
    % Returns the header for a struct
    % Scalar input
    if isscalar(inp)  
        % struct with at least one field
        if  numel(fields(inp)) >= 1
            obj = message('MATLAB:services:printmat:ScalarStructWithFields',getClassnameString(inp, headerLinkAttributes));
            out = [char(32) char(32) obj.getString];
        else
            % struct with no field
            obj = message('MATLAB:services:printmat:ScalarStructWithNoFields',getClassnameString(inp, headerLinkAttributes));
            out = [char(32) char(32) obj.getString];
        end        
    else
    % Non scalar input
    % Empty non-scalar
    if isempty(inp)
        % Empty with at least one field
        if  numel(fields(inp)) >= 1
            obj = message('MATLAB:services:printmat:EmptyStructWithFields',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
            out =  [char(32) char(32)   obj.getString];
        else
            % Empty with no field
            obj = message('MATLAB:services:printmat:EmptyStructVectorWithNoFields',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
            out =  [char(32) char(32)   obj.getString];
        end
    else
        % Non empty non-scalar
        % Non-empty non-scalar with at least one field
        if  numel(fields(inp)) >= 1
            obj = message('MATLAB:services:printmat:StructVectorWithFields',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
            out =  [char(32) char(32)   obj.getString];
        else
            %Non-empty no-scalar with no fields
            obj = message('MATLAB:services:printmat:StructVectorWithNoFields',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
            out =  [char(32) char(32)   obj.getString];
        end
    end        
    end
end

function out = getTabularHeader(inp, headerLinkAttributes)
% Returns the header for a table or timetable

    classname = getClassnameString(inp, headerLinkAttributes);
    
    if isscalar(inp)
        out = [char(32) char(32) classname];
    else
        dims = matlab.internal.display.dimensionString(inp);
        out = [char(32) char(32) dims char(32) classname];
        if isempty(inp)
            % zero case -- message catalog
            obj = message('MATLAB:services:printmat:EmptyTabular',dims, classname);
            out = [char(32) char(32) obj.getString];            
            return
        end
    end
end

function out = getFunctionHandleHeader(inp, headerLinkAttributes)
% Returns the header for a function_handle
    % Scalar function_handle
    if isscalar(inp)
        obj = message('MATLAB:services:printmat:ScalarFunctionHandle',getClassnameString(inp, headerLinkAttributes));
        out = [char(32) char(32) obj.getString];
    else
        % Empty function_handle
        out = getArrayHeader(inp, headerLinkAttributes);
    end    
end

function out = getDoubleHeader(inp, headerLinkAttributes)
    % Doubles do not get a header, unless they are sparse and/or empty
    out = '';
    ndims = numel(size(inp));
    rows = size(inp,1);
    cols = size(inp,2); 
    
    if issparse(inp)
        className = getClassnameString(inp, headerLinkAttributes);
        if ~isreal(inp)
            % Sparse complex double
            if isempty(inp)
                out = getHeaderForEmptySparseComplex(inp, className);
            else
                out = getHeaderForSparseComplex(inp, className);
            end
        else
            % Sparse double
            if isempty(inp)
                out = getHeaderForEmptySparseNumeric(inp, className);
            else
                out = getHeaderForSparseNumeric(inp, className);
            end
        end
    elseif isempty(inp)
        if ~isreal(inp)
            % Empty non-sparse complex double
            out = getHeaderForComplexEmptyNumeric(inp, headerLinkAttributes);
        elseif ~(size(inp,1) == 0 && size(inp, 2) == 0 && numel(size(inp)) == 2)
            if ndims > 2
                % Empty N-dimensional double
                obj = message('MATLAB:services:printmat:EmptyArray',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
            else
                if rows == 1
                    obj = message('MATLAB:services:printmat:EmptyRowVector',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
                elseif cols == 1
                    obj = message('MATLAB:services:printmat:EmptyColumnVector',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
                else
                    obj = message('MATLAB:services:printmat:EmptyMatrix',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
                end
            end
            out = [char(32) char(32) obj.getString];
        end
    end
end

function out = getHeaderForNumericClasses(inp, headerLinkAttributes)
    % Returns the header for all numeric types except double
    if issparse(inp)  % Computes the header for sparse numerics except double
        className = getClassnameString(inp, headerLinkAttributes);  % 'single'
        if ~isreal(inp)
            % Sparse complex single
            if isempty(inp)
                out = getHeaderForEmptySparseComplex(inp, className);
            else
                out = getHeaderForSparseComplex(inp, className);
            end
        else
            % Sparse single
            if isempty(inp)
                out = getHeaderForEmptySparseNumeric(inp, className);
            else
                out = getHeaderForSparseNumeric(inp, className);
            end
        end
    elseif isscalar(inp)
        out = [char(32) char(32) getClassnameString(inp, headerLinkAttributes)];     
    else
        ndims = numel(size(inp));
        rows = size(inp,1);
        cols = size(inp,2);
        if isempty(inp)
                % Empty input
                if ~isreal(inp)
                    % Complex empty
                    out = getHeaderForComplexEmptyNumeric(inp, headerLinkAttributes);
                else
                    % Non-complex empty
                    if ndims > 2
                        obj = message('MATLAB:services:printmat:EmptyArray',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
                        out = [char(32) char(32) obj.getString];
                    else
                        if rows == 1
                            obj = message('MATLAB:services:printmat:EmptyRowVector',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
                            out = [char(32) char(32) obj.getString];
                        elseif cols == 1
                            obj = message('MATLAB:services:printmat:EmptyColumnVector',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
                            out = [char(32) char(32) obj.getString];
                        else
                            obj = message('MATLAB:services:printmat:EmptyMatrix',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
                            out = [char(32) char(32) obj.getString];
                        end
                    end
                end
                
         else
                % Non-empty input
                if ndims > 2
                    obj = message('MATLAB:services:printmat:Array',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
                    out = [char(32) char(32) obj.getString];
                else
                    if rows == 1
                        obj = message('MATLAB:services:printmat:RowVector',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
                        out = [char(32) char(32) obj.getString];
                    elseif cols == 1
                        obj = message('MATLAB:services:printmat:ColumnVector',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
                        out = [char(32) char(32) obj.getString];
                    else
                        obj = message('MATLAB:services:printmat:Matrix',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
                        out = [char(32) char(32) obj.getString];
                    end
                end
        end
     
    end
end

function out = getHeaderForChar(inp, headerLinkAttributes)
    % Returns the header for char
    out = '';
    
    if isempty(inp)
        % Empty input
        obj = message('MATLAB:services:printmat:EmptyArray',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
        out = [char(32) char(32) obj.getString];
    else
        rows = size(inp,1);
        dims = numel(size(inp));
        if (dims > 2) || (rows > 1)
             % Non-empty input  
             obj = message('MATLAB:services:printmat:Array',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
             out = [char(32) char(32) obj.getString];       
        end
    end
    
end

function out = getHeaderForLogicalTypes(inp, headerLinkAttributes)
    % Returns the header for all non numeric types
    className = getClassnameString(inp, headerLinkAttributes);
    if issparse(inp)
        out = getHeaderForSparseMatrixLogical(inp, className);
    else  % Input is not sparse
        if isscalar(inp)
            out = [char(32) char(32) className];
        else
            out = getArrayHeader(inp, headerLinkAttributes);
        end
    end
end

function out = getHeaderForCellArrayTypes(inp, headerLinkAttributes)
    % Returns the header for all non numeric types    
    if isscalar(inp)
        obj = message('MATLAB:services:printmat:Array',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
        out = [char(32) char(32) obj.getString];        
    else
        % Input is not sparse
        out = getArrayHeader(inp, headerLinkAttributes);       
    end
end

function out = getArrayHeader(inp, headerLinkAttributes)
    if isempty(inp)
        % Empty input
        obj = message('MATLAB:services:printmat:EmptyArray',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
        out = [char(32) char(32) obj.getString];
    else
        % Non-empty input  
        obj = message('MATLAB:services:printmat:Array',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
        out = [char(32) char(32) obj.getString];
    end
end

function out = getNonZeroText(inp)
    % Add non-zero count to header
    numNonZeros = nnz(inp);
    if ~isscalar(inp) && numNonZeros > 0  % 1 or more non-zeros and non-scalar
        if numNonZeros == 1
            % "(1 nonzero)"
            nonZeroMsg = message('MATLAB:services:printmat:OneNonzero',numNonZeros);
        else
            % Example: "(2 nonzeros)"
            nonZeroMsg = message('MATLAB:services:printmat:PluralNonzeros',numNonZeros);
        end
        out = [char(32) nonZeroMsg.getString];
    else  % Don't display non-zero message if there are 0 non-zeros
        out = '';
    end
end

function out = getHeaderForSparseNumeric(inp, className)
    if matlab.internal.display.isHot  % Display includes hyperlinks
        if isscalar(inp)  % For scalars, we omit the dimension string and shape description
            % Example: "sparse double"
            headerMsg = message('MATLAB:services:printmat:SparseNumericScalar', className);
        elseif isrow(inp)
            % Example: "1x2 sparse double row vector"
            headerMsg = message('MATLAB:services:printmat:SparseNumericRowVector', ...
                matlab.internal.display.dimensionString(inp), className);
        elseif iscolumn(inp)
            % Example: "2x1 sparse double column vector"
            headerMsg = message('MATLAB:services:printmat:SparseNumericColumnVector', ...
                matlab.internal.display.dimensionString(inp), className);
        else
            % Example: "2x2 sparse double matrix"
            headerMsg = message('MATLAB:services:printmat:SparseNumericMatrix', ...
                matlab.internal.display.dimensionString(inp), className);
        end
    else  % Display does not include hyperlinks
        if isscalar(inp)
            % Example: "sparse double"
            headerMsg = message('MATLAB:services:printmat:SparseNumericScalarNoHyperlink', className);
        elseif isrow(inp)
            % Example: "1x2 sparse double row vector"
            headerMsg = message('MATLAB:services:printmat:SparseNumericRowVectorNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
        elseif iscolumn(inp)
            % Example: "2x1 sparse double column vector"
            headerMsg = message('MATLAB:services:printmat:SparseNumericColumnVectorNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
        else
            % Example: "2x2 sparse double matrix"
            headerMsg = message('MATLAB:services:printmat:SparseNumericMatrixNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
        end
    end
    % Example full output message: "2x1 sparse double row vector (2 nonzeros)"
    out = [char(32) char(32) headerMsg.getString getNonZeroText(inp)];
end

function out = getHeaderForEmptySparseNumeric(inp, className)
    if matlab.internal.display.isHot  % Display includes hyperlinks
        if isrow(inp)
            % Example: "1x0 empty sparse double row vector"
            headerMsg = message('MATLAB:services:printmat:EmptySparseRowVector', ...
                matlab.internal.display.dimensionString(inp), className);
        elseif iscolumn(inp)
            % Example: "0x1 empty sparse double column vector"
            headerMsg = message('MATLAB:services:printmat:EmptySparseColumnVector', ...
                matlab.internal.display.dimensionString(inp), className);
        else
            % Example: "0x0 empty sparse double matrix"
            headerMsg = message('MATLAB:services:printmat:EmptySparseMatrix', ...
                matlab.internal.display.dimensionString(inp), className);
        end
    else  % Display does not include hyperlinks
        if isrow(inp)
            % Example: "1x0 empty sparse double row vector"
            headerMsg = message('MATLAB:services:printmat:EmptySparseRowVectorNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
        elseif iscolumn(inp)
            % Example: "0x1 empty sparse double column vector"
            headerMsg = message('MATLAB:services:printmat:EmptySparseColumnVectorNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
        else
            % Example: "0x0 empty sparse double matrix"
            headerMsg = message('MATLAB:services:printmat:EmptySparseMatrixNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
        end
    end
    % Example full output message: "0x1 empty sparse double matrix column vector"
    out = [char(32) char(32) headerMsg.getString];
end

function out = getHeaderForSparseComplex(inp, className)
    if matlab.internal.display.isHot  % Display includes hyperlinks
        if isscalar(inp)
            % Example: "sparse complex double"
            headerMsg = message('MATLAB:services:printmat:SparseComplexScalar', className);
        elseif isrow(inp)
            % Example: "1x2 sparse complex double row vector"
            headerMsg = message('MATLAB:services:printmat:SparseComplexRowVector', ...
                matlab.internal.display.dimensionString(inp), className);
        elseif iscolumn(inp)
            % Example: "2x1 sparse complex double column vector"
            headerMsg = message('MATLAB:services:printmat:SparseComplexColumnVector', ...
                matlab.internal.display.dimensionString(inp), className);
        else
            % Example: "2x2 sparse complex double matrix"
            headerMsg = message('MATLAB:services:printmat:SparseComplexMatrix', ...
                matlab.internal.display.dimensionString(inp), className);
        end
    else  % Display does not include hyperlinks
        if isscalar(inp)
            % Example: "sparse complex double"
            headerMsg = message('MATLAB:services:printmat:SparseComplexScalarNoHyperlink', className);
        elseif isrow(inp)
            % Example: "1x2 sparse complex double row vector"
            headerMsg = message('MATLAB:services:printmat:SparseComplexRowVectorNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
        elseif iscolumn(inp)
            % Example: "2x1 sparse complex double column vector"
            headerMsg = message('MATLAB:services:printmat:SparseComplexColumnVectorNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
        else
            % Example: "2x2 sparse complex double matrix"
            headerMsg = message('MATLAB:services:printmat:SparseComplexMatrixNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
        end
    end
    % Example full output message: "2x2 sparse complex double matrix (1 nonzero)"
    out = [char(32) char(32) headerMsg.getString getNonZeroText(inp)];
end

function out = getHeaderForEmptySparseComplex(inp, className)
    if matlab.internal.display.isHot  % Display includes hyperlinks
        if isrow(inp)
            % Example: "1x0 empty sparse complex double row vector"
            headerMsg = message('MATLAB:services:printmat:EmptySparseComplexRowVector', ...
                matlab.internal.display.dimensionString(inp), className);
        elseif iscolumn(inp)
            % Example: "0x1 empty sparse complex double column vector"
            headerMsg = message('MATLAB:services:printmat:EmptySparseComplexColumnVector', ...
                matlab.internal.display.dimensionString(inp), className);
        else
            % Example: "0x0 empty sparse complex double matrix"
            headerMsg = message('MATLAB:services:printmat:EmptySparseComplexMatrix', ...
                matlab.internal.display.dimensionString(inp), className);
        end
    else  % Display does not include hyperlinks
        if isrow(inp)
            % Example: "1x0 empty sparse complex double row vector"
            headerMsg = message('MATLAB:services:printmat:EmptySparseComplexRowVectorNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
        elseif iscolumn(inp)
            % Example: "0x1 empty sparse complex double column vector"
            headerMsg = message('MATLAB:services:printmat:EmptySparseComplexColumnVectorNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
        else
            % Example: "0x0 empty sparse complex double matrix"
             headerMsg = message('MATLAB:services:printmat:EmptySparseComplexMatrixNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
        end
    end
    % Example full output message: "0x0 empty sparse complex double matrix"
    out = [char(32) char(32) headerMsg.getString];
end

function out = getHeaderForSparseMatrixLogical(inp, className)
    if matlab.internal.display.isHot  % Display includes hyperlinks
        if isempty(inp)  % empty logical array
            headerMsg = message('MATLAB:services:printmat:EmptySparseArray', ...
                matlab.internal.display.dimensionString(inp), className);
            % Example full output message: "0x0 empty sparse logical array"
            out = [char(32) char(32) headerMsg.getString];
        elseif isscalar(inp)  % scalar logical
            headerMsg = message('MATLAB:services:printmat:SparseLogicalScalar', className);
            % Example full output message: "sparse logical (1 nonzero)"
            out = [char(32) char(32) headerMsg.getString getNonZeroText(inp)];
        else  % non-empty, non-scalar logical array
            headerMsg = message('MATLAB:services:printmat:SparseLogicalVector', ...
                matlab.internal.display.dimensionString(inp), className);
            % Example full output message: "1x2 sparse logical array (2 nonzeros)"
            out = [char(32) char(32) headerMsg.getString getNonZeroText(inp)];
        end
    else  % Display does not include hyperlinks
        if isempty(inp)  % empty logical array
            headerMsg = message('MATLAB:services:printmat:EmptySparseArrayNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
            % Example full output message: "0x0 empty sparse logical array"
            out = [char(32) char(32) headerMsg.getString];
        elseif isscalar(inp)  % scalar logical
            headerMsg = message('MATLAB:services:printmat:SparseLogicalScalarNoHyperlink', className);
            % Example full output message: "sparse logical (1 nonzero)"
            out = [char(32) char(32) headerMsg.getString getNonZeroText(inp)];
        else  % non-empty, non-scalar logical array
            headerMsg = message('MATLAB:services:printmat:SparseLogicalVectorNoHyperlink', ...
                matlab.internal.display.dimensionString(inp), className);
            % Example full output message: "1x2 sparse logical array (2 nonzeros)"
            out = [char(32) char(32) headerMsg.getString getNonZeroText(inp)];
        end
    end
end

function header = getHeaderForEnum(inp, headerLinkAttributes)    
    
    if isempty(inp)
        % Empty enumeration
        obj = message('MATLAB:ClassText:DISPLAY_EMPTY_ENUMERATION_LABEL', matlab.internal.display.dimensionString(inp), getClassnameString(inp, headerLinkAttributes));        
    else
        % Non-empty enumeration
        if isscalar(inp)
            % Scalar
            obj = message('MATLAB:ClassText:SCALAR_ENUMERATION_HEADER', getClassnameString(inp, headerLinkAttributes));
        else
            % Non-scalar
            obj = message('MATLAB:ClassText:ENUMERATION_ARRAY_HEADER', matlab.internal.display.dimensionString(inp), getClassnameString(inp, headerLinkAttributes));
        end
    end   
    
    header = [char(32) char(32) obj.getString];
end

function out = getClassNameForEnums(inp)
    %  If input is an enum, strip the package name if any
    out = '';
    if isenum(inp)
        str = class(inp);
        idx = regexp(str, '\.');
        if ~isempty(idx)
            out = str(idx(end)+1:end);
        else
            out = str;
        end
    end
end

function out = getHeaderForComplexEmptyNumeric(inp, headerLinkAttributes)
    if matlab.internal.display.isHot
        if isrow(inp)
        % Empty row vector
            obj = message('MATLAB:services:printmat:EmptyComplexRowVector',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
        elseif iscolumn(inp)
        % Empty column vector
            obj = message('MATLAB:services:printmat:EmptyComplexColumnVector',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
        elseif numel(size(inp)) == 2
        % Empty matrix
            obj = message('MATLAB:services:printmat:EmptyComplexMatrix',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
        else
        % Empty array
            obj = message('MATLAB:services:printmat:EmptyComplexArray',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
        end    
    else
        if isrow(inp)
        % Empty row vector
            obj = message('MATLAB:services:printmat:EmptyComplexRowVectorNoHyperlink',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
        elseif iscolumn(inp)
        % Empty column vector
            obj = message('MATLAB:services:printmat:EmptyComplexColumnVectorNoHyperlink',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
        elseif numel(size(inp)) == 2
        % Empty matrix
            obj = message('MATLAB:services:printmat:EmptyComplexMatrixNoHyperlink',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
        else
        % Empty array
            obj = message('MATLAB:services:printmat:EmptyComplexArrayNoHyperlink',matlab.internal.display.dimensionString(inp),getClassnameString(inp, headerLinkAttributes));
        end        
     end
    
    out = [char(32) char(32) obj.getString];
end

function out = getClassnameString(inp, headerLinkAttributes)
    % Returns the classname string
    if isenum(inp)
        classname = getClassNameForEnums(inp);
    else
        classname = class(inp);
    end
    
    if matlab.internal.display.isHot
        out = ['<a href="matlab:helpPopup(''' class(inp) ''')" ' headerLinkAttributes '>' classname '</a>'];
    else
        out = classname;
    end          
end
