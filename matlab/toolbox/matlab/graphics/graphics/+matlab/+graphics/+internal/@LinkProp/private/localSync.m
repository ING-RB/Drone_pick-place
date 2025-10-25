% Local function used by LinkProp & helpers
%
function localSync(hLink)
% LOCALSYNC Make sure all linked property values are synchronized across
% Target objects

%   Copyright 2014-2020 The MathWorks, Inc.

propnames = get( hLink, 'PropertyNames' );
valid = get( hLink, 'ValidProperties' );
hlist = hLink.Targets;
for n = 1:length( propnames )
    prop = propnames{ n };
    ind = find( valid( :, n ) );
    if length( ind )>1
        
        values = get( hLink, 'SharedValues' );
        val = get( hlist( ind( 1 ) ), prop );
        
        % filter out values which are equal to new value
        list = hlist( ind );
        doSet = true( 1, length( list ) );
        doSet( 1 ) = false;
        for k = 2:length( list )
            if isequal( { val }, { get( list( k ), prop ) } )
                doSet( k ) = false;
            end
        end
        list = list( doSet );
        set( list, prop, val );
        values{ n } = val;
        set( hLink, 'SharedValues', values );
    end
end
end
