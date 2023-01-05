%  PROCESS RESULTS of TEXTLOG files from RCS_logs to visualize the adapative state changes during CL stim (group D)
%
%
%
% PShirvalkar 12/2022
clear
close all

PATIENTIDside = 'RCS02R';

rootdir = '/Volumes/PrasadX5/spiritdata/raw' ;


% Load files
PATIENTID = PATIENTIDside(1:end-1);
fn = [PATIENTIDside '_textlogs.mat'];
load(fullfile(rootdir,PATIENTID,fn),'textlog');

%% Find where group changes =  D (CL)

Didx = strcmp(textlog.groupchange.group,'D');
% diffD = diff(Didx); use this to avoid looking at consecutive  group Ds (to treat them as one
% block,  -1 is start,  1 is end of block)

Dstarts  = textlog.groupchange.time(Didx);

% if D is the last group make last time now
if Didx(end)==1
    Dends = textlog.groupchange.time(find(Didx(1:end-1))+1);
    Dends(end+1) = datestr(now);
else
    Dends = textlog.groupchange.time(find(Didx)+1);
end

Ddurations  = duration(Dends-Dstarts);
long_durations_ind = Ddurations > duration(1,0,0); % greater than 1 hour

histogram(Ddurations(long_durations_ind),20);
xlabel('duration hours')
title('Distribution of Closed Loop session durations > 1 hour')



%% Long Ds
Dstartlongs = Dstarts(long_durations_ind);
Dendlongs = Dends(long_durations_ind);
statechanges  = [];
percent_on = [];
TEED=[];
textlog.app.time.TimeZone = Dstartlongs.TimeZone;

for x= 1:length(Dstartlongs)
    %1. Use textlog.app to calculate TEED
    %2. Compare textlog.app with textlog.adaptive - which statechange to use?
    %3. For textlog.app, note that the prog0 amplitude corresponds to the OLD state, so use the prior
    %          duration's state change for that duration

    currentDidx = [];
    currentapp = [];

    % Collect the state info between each start to end time points
    currentDidx = textlog.app.time >= Dstartlongs(x) & textlog.app.time <= Dendlongs(x);
    currentapp = textlog.app(currentDidx,:);

    % ****FIND # of state changes
    statechanges(x) = sum(currentDidx);


    on_idx = find(currentapp.prog0 >0 & ~(currentapp.newstate == 15)); % this prevents detection of state changes where stim stays on

    %  *****  FIND % of time On
    if ~isempty(on_idx)
clc
        totalduration = Dendlongs(x) - Dstartlongs(x);

        % if the closed loop state starts with stimulation ON, then add the time since when group D started;
        if on_idx(1)==1
            onduration = sum(currentapp.time(on_idx(2:end)) - currentapp.time(on_idx(2:end)-1));
            onduration =  onduration + (currentapp.time(1)-Dstartlongs(x));
        else
            onduration = currentapp.time(on_idx) - currentapp.time(on_idx-1);
        end


        percent_on(x) = (sum(onduration) / totalduration) * 100;




        %  find TEED Per hour
        %             TEED= (fq * pw * V^2) / R * 1s;
        %               TEED  = fq * pw * ampcurrent^2 * R * 1s 
          
        

        fqidx = find(currentapp.prog0>0,1,'first'); %assumes that stim Amp was not changed in middle, and that all stim goe from 0mA -> >0mA
        fq = currentapp.rateHz(fqidx);
        pw = 200 * 10^-6;
        amp = currentapp.prog0(fqidx);
        R= 10000; %10k ohmz, but get real impedance
        TEED(x) = (fq * pw * amp^2 * R * seconds(sum(onduration)) ) / hours(totalduration);

    else

        percent_on(x) = 0;
        TEED(x) = 0;
    end


end





subplot 321
histogram(statechanges,100)
title('statechanges')
subplot 322
scatter(Dstartlongs,statechanges,'filled')
title('statechanges')

subplot 323
histogram(percent_on,100)
title('percent_on')
subplot 324
scatter(Dstartlongs,percent_on,'filled')
title('percent_on')
% ylim([0 100])

subplot 325
histogram(TEED,100)
title('TEED per hour')
subplot 326
scatter(Dstartlongs,TEED,'filled')
title('TEED per hour')
sgtitle(PATIENTIDside)


%% Plot the adaptive state changes/ current of stimulation for a specific Closed loop run
subplot 211
stairs(currentapp.time,currentapp.newstate)
ylabel('state')
subplot 212
plot(currentapp.time,currentapp.prog0)
ylabel('current')


