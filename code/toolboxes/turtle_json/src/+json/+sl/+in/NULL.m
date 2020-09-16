classdef NULL
    %
    %   Class:
    %   sl.in.NULL
    %
    %   This class can be set as a default option and it will be removed 
    %   when splitting  in "sl.in.splitAndProcessVarargin"
    %
    %   This is useful for allowing defaults in subfunctions.
    %
    %   See Also:
    %   sl.in.splitAndProcessVarargin
    %
    %   Example:
    %   --------
    %   in.test = sl.in.NULL
    %   in.cheese = 2
    %
    %   TODO: finish call to sl.in.splitAndProcessVarargin
    %
    %   If 'test' is not passed in as an option, it will not exist
    %   as a field in the 'in' struct following sl.in.splitAndProcessVarargin
end

