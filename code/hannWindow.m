function hann_win = hannWindow(L,percentage)
% calcualtes hann window given window size L and percentage (25%,50%,100%)
% input
% (1) L: window size (integer)
% (2) Percentage: '25% Hann', '50% Hann' or '100% Hann' (string) (default, '100% Hann')

if nargin ==0
    error('you need to provide at least the number of window samples L')
elseif nargin ==1
    percentage = '100%';
elseif nargin > 2
    error('too many input arguments')
end
     
switch percentage
    case '100% Hann'
        hann_win = 0.5*(1-cos(2*pi*(0:L-1)/(L-1))); % create hann taper function, equivalent to the Hann 100%         
    case '50% Hann'
        temp_win = 0.5*(1-cos(4*pi*(0:L-1)/(L-1))); % create hann taper function, equivalent to the Hann 50% 
        hann_win = sethannwindow(temp_win);                
    case '25% Hann'
        temp_win = 0.5*(1-cos(8*pi*(0:L-1)/(L-1))); % create hann taper function, equivalent to the Hann 250% 
        hann_win = sethannwindow(temp_win);  
end

% adding this to match length of hann window and fft size (needs debugging)
if length(hann_win) > L && mod(length(hann_win),L) == 2
    hann_win = hann_win(2:end-1);    
end

end

function hann_out = sethannwindow(temp_win)
    % sets hann window flat top in case is not at 100% hann window 
     [maxvals,indeces] = findpeaks(temp_win);
     temp_win_middle = ones(1,length(indeces(1)-1:indeces(end)-1));
     temp_win_left  = temp_win(1:indeces(1));
     temp_win_right = temp_win(indeces(end):end);
     hann_out = [temp_win_left temp_win_middle temp_win_right];        
end
        