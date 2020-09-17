function sratesout = getSampleRateAcc(srates)
%% input: matrix of sample rates of each packet from TimeDomainData.Json 
%% output: sample rate in Hz 


if length(unique(srates)) > 1 
    warning('you have non uniform sample rates in your data'); 
end




fprintf('out of %d packets:\n\t%d packets at 250Hz\n\t%d packets at 500Hz\n \t%d packets at 1000Hz\n',...
    length(srates),...
    sum((srates==0)),...
    sum((srates==1)),...
    sum((srates==2)));

% make sample rates numbers 
sratesout = srates; 
sratesout(srates==0) = 64;
sratesout(srates==1) = 32;
sratesout(srates==2) = 16;
sratesout(srates==3) = 8;
sratesout(srates==4) = 4;
sratesout(srates==255) = NaN;

clear temp*; 
