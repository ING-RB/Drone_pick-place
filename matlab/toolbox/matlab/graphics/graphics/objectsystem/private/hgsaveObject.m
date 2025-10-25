function Obj = hgsaveObject(h)
%hgsaveObject Save object handles natively.
%
%  hgsaveObject prepares graphics objects for serialization.  Only
%  properties with a Serializable property which is set to true should be
%  saved.

%   Copyright 2009-2018 The MathWorks, Inc.

if ~isempty(h)
    %Temporary code to circumvent failure. Only have 'else' clause after
    %feature flag is removed. 
    if ~feature('OnOffSwitchState')
        % Filter out non-serializable objects
        hasSer = isprop(h, 'Serializable');
        IsSer = get(h(hasSer), {'Serializable'});
        
        DoSer = ~hasSer;
        DoSer(hasSer) = strcmp(IsSer, 'on');
        Obj = h(DoSer);
    else
        % Find all objects with a Serializable property
        hasSerializable = isprop(h, 'Serializable');
        
        % Get the values of the Serializable properties
        IsSerializable = get(h(hasSerializable), {'Serializable'});
        %get returns a cell array - convert to array of OnOffSwitchState so we
        %can use it in logical indexing
        IsSerializable = [IsSerializable{:}];
        
        doSerialize = ~hasSerializable;
        doSerialize(hasSerializable) = IsSerializable;
        Obj = h(doSerialize);
    end
else
    Obj = h;
end
Obj = Obj(:).';
