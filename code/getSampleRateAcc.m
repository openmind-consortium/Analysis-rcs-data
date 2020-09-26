function sratesout = getSampleRateAcc(srates)
%%
% Input: matrix of sample rates of each packet from RawDataAccel.Json 
% Output: sample rate in Hz 
%%

if length(unique(srates)) > 1 
    warning('you have non uniform sample rates in your data'); 
end

% Convert sample rate codes to Hz
sratesout = srates; 
sratesout(srates==0) = 64;
sratesout(srates==1) = 32;
sratesout(srates==2) = 16;
sratesout(srates==3) = 8;
sratesout(srates==4) = 4;
sratesout(srates==255) = NaN;

end 
