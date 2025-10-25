function frac = progress(nds)
%PROGRESS   Return the fraction of data read from the NestedDatastore.
%
%   The PROGRESS method will return:
%   - 0 if no data has been read yet,
%   - 1 if all the data has been read, and
%   - a value between 0 and 1 if some reads are completed, but not all.
%
%   The fraction returned by the PROGRESS method will monotonically increase
%   after each READ method call until it reaches 1.
%
%   The fraction returned by the PROGRESS method can be reset back to 0 by
%   calling the RESET method on the NestedDatastore.

%   Copyright 2021 The MathWorks, Inc.

    % Can only return the progress through the OuterDatastore, since
    % NestedDatastore doesn't know about the InnerDatastore's granularity.
    frac = nds.OuterDatastore.progress();
end
