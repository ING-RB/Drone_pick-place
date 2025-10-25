function wc = wordcloud(varargin)
%WORDCLOUD Word cloud chart for tall data
%   WC = WORDCLOUD(TBL,WORDVAR,SIZEVAR)
%   WC = WORDCLOUD(C)
%   WC = WORDCLOUD(WORDS, SIZEDATA)
%   WC = WORDCLOUD(___,Name,Value)
%   WC = WORDCLOUD(parent,___)
%
%   Limitations for tall table input:
%   1. The WC = WORDCLOUD(TEXT) syntax is not supported.
%   2. When WORDS and SIZEDATA are provided as tall arrays, these will be
%   gathered and must fit into memory.
%
%   See also: WORDCLOUD, TALL.

%   Copyright 2017-2022 The MathWorks, Inc.

% No matter what the syntax is, the first input must be tall.
tall.checkIsTall(upper(mfilename), 1, varargin{1});

inAdap = matlab.bigdata.internal.adaptors.getAdaptor(varargin{1});
if inAdap.Class == "categorical"
    % WORDCLOUD(C). We need to build the summary data.
    tall.checkNotTall(upper(mfilename), 1, varargin{2:end});
    [counts, words] = histcounts(varargin{1});
    [words, counts] = gather(string(words), counts);
    % Expected in frequency order
    [counts,inds] = sort(counts, 'descend');
    words = words(inds);
    wc = wordcloud(words, counts, varargin{2:end});
    
elseif inAdap.Class == "table"
    % WORDCLOUD(TBL,WORDVAR,SIZEVAR)
    tall.checkNotTall(upper(mfilename), 1, varargin{2:end});
    [tbl, wordvar, sizevar] = deal(varargin{1:3});
    iValidateTableSubscript(tbl, wordvar, 'WordVariable')
    iValidateTableSubscript(tbl, sizevar, 'SizeVariable')
    wc = wordcloud(gather(tbl), varargin{2:end});
    
else
    % WORDCLOUD(WORDS, SIZEDATA)
    % Watch out for a scalar text argument (i.e. WORDCLOUD(TEXT)) as this
    % requires text analytics toolbox.
    if nargin<2 || ~istall(varargin{2})
        error(message('MATLAB:graphics:wordcloud:SingleWordInput'));
    end
    tall.checkNotTall(upper(mfilename), 2, varargin{3:end});
    [words, counts] = varargin{1:2};
    [words, counts] = validateSameTallSize(words, counts);
    words = tall.validateTypeWithError(words, 'wordcloud', 1, ...
                                       ["string" "cellstr"], "MATLAB:graphics:wordcloud:WordInput");
    counts = tall.validateTypeWithError(counts, 'wordcloud', 2, ...
                                        "numeric", "MATLAB:graphics:wordcloud:SingleWordInput");
    [words, counts] = gather(words, counts);
    wc = wordcloud(words, counts, varargin{3:end});
end

end



function iValidateTableSubscript(tbl, var, propName)
% Helper to check that VAR is a valid subscript for extracting a single
% variable from TBL.
try
    data = subselectTabularVars(tbl, var);
catch err
    % Substitute special subscript error
    throwAsCaller(MException(message('MATLAB:Chart:TableSubscriptInvalid', propName)));
end

if width(data)~=1
    throwAsCaller(MException(message('MATLAB:Chart:NonScalarTableSubscript', propName)));
end
end
