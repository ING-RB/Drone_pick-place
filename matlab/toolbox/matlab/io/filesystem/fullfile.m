function f = fullfile(varargin)
    
    narginchk(1, Inf);

    theInputs = varargin;

    containsCellOrStringInput = false;
    containsStringInput = false; 

    for i = 1:nargin

        inputElement = theInputs{i};
        
        containsCellOrStringInput = containsCellOrStringInput || iscell(inputElement);
        
        if isstring(inputElement)
            containsStringInput = true; 
            containsCellOrStringInput = true; 
            theInputs{i} = convertStringsToChars(theInputs{i});
        end
    
        if ~ischar(theInputs{i}) && ~iscell(theInputs{i}) && ~isnumeric(theInputs{i}) && ~isreal(theInputs{i})
            error(message('MATLAB:fullfile:InvalidInputType'));
        end

    end
    
    f = theInputs{1};
    
    % Note: this can return a scalar or vector.
    isIRI = matlab.io.internal.vfs.validators.isIRI(f);

    % The first folder(s) need to be the same type because the rest of the
    % code can't handle a mixture of separators.
    if all(~isIRI)
       fs = filesep;
    elseif all(isIRI)
       fs = '/';
    else
        error(message('MATLAB:fullfile:MixedInputType'));
    end

    try
       if nargin == 1
            if ~isnumeric(f)
                f = refinePath(f, fs, isIRI);
            else 
                f = char(f); 
            end
        else
            if containsCellOrStringInput
                theInputs(cellfun(@(x)~iscell(x)&&isempty(x), theInputs)) = [];
            else
                theInputs(cellfun('isempty', theInputs)) = '';
            end

            if length(theInputs)>1
                theInputs{1} = ensureTrailingFilesep(theInputs{1}, fs);
            end
            if ~isempty(theInputs)
                theInputs(2,:) = {fs};
                theInputs{2,1} = '';
                theInputs(end) = '';
                if containsCellOrStringInput
                    f = strcat(theInputs{:});
                else
                    f = [theInputs{:}];
                end
            end
            f = refinePath(f, fs, isIRI);
        end
    catch
        locHandleError(theInputs(1,:));
    end
    
    if containsStringInput
        f = string(f);
    end
end

function f = ensureTrailingFilesep(f,fs)
    if iscell(f)
        for i=1:numel(f)
            f{i} = addTrailingFileSep(f{i},fs);
        end
    else
        f = addTrailingFileSep(f,fs);
    end
end

function str = addTrailingFileSep(str, fs)
    if ~isempty(str) && (str(end) ~= fs && ~(ispc && str(end) == '/'))
        str = [str, fs];
    end
end

function f = refinePath(f, fs, isIRI)
       
    singleDotPattern = [fs '.' fs];
    multipleFileSepPattern = [fs, fs];
    
    if fs ~= '/'
        f = strrep(f, '/', fs);
    end
    
    if any(contains(f, singleDotPattern))
        f = replaceSingleDots(f, fs);
    end

    % For non-IRIs, replace multiple file seperators
    if ~isIRI 
        if any(contains(f, multipleFileSepPattern))
            f = replaceMultipleFileSeps(f, fs);
        end
    end
    
end

function f = replaceMultipleFileSeps(f, fs)   
    % Note: This function is not meant to work with IRIs.
    % Collapse repeated file separators unless they appear at the
    % beginning. If in the beginning, keep only up to two.

    persistent fsEscape multipleFileSepRegexpPattern 
    if isempty(fsEscape)
        fsEscape = ['\', fs];
        multipleFileSepRegexpPattern = ['(', fsEscape, ')', fsEscape '+'];
        if ispc
            drive = '([a-zA-Z]:)';
            winUNC = '(\\)';
            longname = '(\\\\\?\\.*)';
            multipleFileSepRegexpPattern = ['^(' drive '|' longname '|' winUNC ')|' multipleFileSepRegexpPattern];
        else
            % Keep the first file separator, if any, intact so
            % that the regexprep replacement for multiple file separators
            % in the input path is applied only after the first one at the
            % beginning.
            pathBeginning = ['(' fsEscape ')'];
            multipleFileSepRegexpPattern = ['^(' pathBeginning ')|', multipleFileSepRegexpPattern];
        end
    end
    f = regexprep(f, multipleFileSepRegexpPattern , '$1', 'ignorecase');
end

function f = replaceSingleDots(f, fs)   
    fsEscape = ['\', fs];
    singleDotRegexpPattern = ['(',fsEscape,')', '(?:\.', fsEscape, ')+'];
    if ispc
        singleDotRegexpPattern = ['(^\\\\(\?\\.*|\.(?=\\)))|' singleDotRegexpPattern];
    end

    f = regexprep(f, singleDotRegexpPattern, '$1');
end

function locHandleError(theInputs)
    firstNonscalarCellArg = struct('idx', 0, 'size', 0);
    for argIdx = 1:numel(theInputs)
        currentArg = theInputs{argIdx};
        if isscalar(currentArg)
            continue;
        elseif ischar(currentArg) && ~isrow(currentArg) && ~isempty(currentArg)
            throwAsCaller(MException(message('MATLAB:fullfile:NumCharRowsExceeded')));
        elseif iscell(currentArg)
            currentArgSize = size(currentArg);
            if firstNonscalarCellArg.idx == 0
                firstNonscalarCellArg.idx = argIdx;
                firstNonscalarCellArg.size = currentArgSize;
            elseif ~isequal(currentArgSize, firstNonscalarCellArg.size)
                throwAsCaller(MException(message('MATLAB:fullfile:CellstrSizeMismatch')));
            end
        end
    end
    throwAsCaller(MException(message('MATLAB:fullfile:InvalidInputType')));
end

%   Copyright 1984-2023 The MathWorks, Inc.
