function [therapyStatusDescription] = convertTherapyStatus(therapyStatus)
%%
% Takes information from therapyStatus and create therapyStatusDescription
%%
switch therapyStatus
    case 0
        therapyStatusDescription = 'Off';
    case 1
        therapyStatusDescription = 'On';
    case 2
        therapyStatusDescription = 'Lead integrity test';
    case 3
        therapyStatusDescription = 'Transitioning to off';
    case 4
        therapyStatusDescription = 'Transitioning to active';
    case 5
        therapyStatusDescription = 'Transitioning to lead integrity test';
    otherwise 
        therapyStatusDescription = 'Unexpected';
end

end