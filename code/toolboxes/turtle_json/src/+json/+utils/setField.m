function varargout = setField(varargin) %#ok<STOUT>
%
%   This function can be used to set an invalid field name in a structure.
%
%   Example
%   -------
%   s = struct;
%   wtf = json.utils.setField(s,'wtf batman',5);
%
%   %result
%   >> wtf
%
%   wtf = 
% 
%     struct with fields:
% 
%       wtf batman: 5
%
%   %data access
%   >> wtf.('wtf batman')
%
%   ans =
%
%        5


error('Mex function setField.c not compiled')