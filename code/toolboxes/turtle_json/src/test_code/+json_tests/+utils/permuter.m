function data_out = permuter(data_in)
%
%   json_tests.utils.permuter

%We'll toggle this based on our encoder

%For now we'll permute

n_dims = ndims(data_in);
data_out = permute(data_in,n_dims:-1:1);

end