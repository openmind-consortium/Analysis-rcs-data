function sratesout = getSampleRateAcc(srates)
%%
% Input: matrix of sample rates of each packet from RawDataAccel.Json 
% Output: sample rate in Hz 

% Specific decimal values obtained from Medtronic
%%

if length(unique(srates)) > 1 
    warning('you have non uniform sample rates in your data'); 
end

% Convert sample rate codes to Hz
sratesout = srates; 
sratesout(srates==0) = 65.104;
sratesout(srates==1) = 32.552;
sratesout(srates==2) = 16.276;
sratesout(srates==3) = 8.138;
sratesout(srates==4) = 4.069;
sratesout(srates==255) = NaN;

end 
