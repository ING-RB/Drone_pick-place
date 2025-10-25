function varargout = checkcode( varargin )
%

%   Copyright 1984-2018 The MathWorks, Inc.

    if any(cellfun(@(x) isstring(x) && any(ismissing(x)), varargin))
        error(message('MATLAB:mlint:MissingString'));
    end

    if nargin > 0
        [varargin{:}] = convertStringsToChars(varargin{:});
    end

    try
        %% === Parse input arguments ===
        narginchk(1, inf);
        nargoutchk(0,2);
        validateInputs(varargin{:});
        parser = matlab.internal.codeanalyzer.inputParser();
        parser.parse( nargout, varargin{:} );

        % Ensure that when asking for output type "display" there are no output
        % arguments.
        if( strcmp( parser.outputType, 'display' ) && nargout > 0 )
            error( message( 'MATLAB:mlint:TooManyOutputArguments' ) );
        end

        %% === Get code analyzer messages ===
        mlntMsg = matlab.internal.codeanalyzer.getMessages( parser );

        %% === Modify and return/display output ===

        % Get an object to process the messages
        msgOutput = matlab.internal.codeanalyzer.getMessageOutputObject( parser.outputType, parser.fileListWasCell, parser.files, parser.hasText, parser.msgIdsWereRequested );

        % Process the message and return output
        [varargout{1:nargout-1}] = msgOutput.output( mlntMsg );
        if( nargout > 1 )
            % Since the messages are returned as a column vector, return the
            % list of files also as a column vector
            files = parser.files;
            if( isrow( files ) )
                files = files';
            end
            varargout{ 2 } = files;
        end

    catch e
        throw( e );
    end



end

function validateInputs(varargin)

% check that there are atmost one cell input
% Only the input files to be checked can be in a cell format. However, this check will not resolve the filenames
    cellArgIdx = cellfun( @iscell, varargin);
    numCellsInInputs = sum(cellArgIdx);

    if (numCellsInInputs > 1)
        error( message( 'MATLAB:mlint:TooManyCellArgs' ) );
    else
        charArgIdx = cellfun(@ischar, varargin);
        if any(cellfun(@(x) ischar(x) && isempty(x), varargin))
            error(message('MATLAB:mlint:EmptyInput'));
        end

        notCharVector = cellfun(@(x) ischar(x) && ~isrow(x), varargin);
        if any(notCharVector)
            error(message('MATLAB:mlint:NotCharacterRowVector'));
        end

        if (numCellsInInputs == 0)
            % no cell input , all the inputs must be of char type
            if (~all(charArgIdx))
                error( message( 'MATLAB:mlint:CheckCodeInputMustBeOfCharType' ) );
            end
        elseif (numCellsInInputs == 1)
            % single cell input with character type only arguments
            numNonCharInputs = sum(~charArgIdx);

            if any(cellfun(@(x) ischar(x) && isempty(x), varargin{cellArgIdx}))
                error(message('MATLAB:mlint:EmptyInput'));
            end

            if (numNonCharInputs > 1)
                error(message( 'MATLAB:mlint:CheckCodeInputMustBeOfCharType' ) );
            end

            % single cell input, only valid for files
            % cannot be a nested input

            % there should be only one cell input at this point. Otherwise this should be caught by the previous elseif block
            singleCellInputContent = varargin(cellArgIdx);
            nestedCellIdx = cellfun(@iscell, singleCellInputContent{:});

            if ( any( nestedCellIdx))
                error( message( 'MATLAB:mlint:NestedCell' ) );
            end

            fileInputCharArgIdx = cellfun(@(x)ischar(x), singleCellInputContent{:});
            if( ~all( fileInputCharArgIdx))
                error( message( 'MATLAB:mlint:CheckCodeInputMustBeOfCharType' ) );
            end

            if any(cellfun(@(x) ischar(x) && ~isrow(x), singleCellInputContent{:}))
                error(message('MATLAB:mlint:NotCharacterRowVector'));
            end
        end
    end

end
