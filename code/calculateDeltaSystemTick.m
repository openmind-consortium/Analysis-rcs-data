function currentDelta = calculateDeltaSystemTick(systemTick_previous, systemTick_next)
%%
% Returns the difference between systemTick_next and
% systemTick_previous, assuming systemTick_next comes after
% systemTick_previous; a 'circular calculator' for systemTick
%%

currentDelta = mod((systemTick_next + (2^16) - systemTick_previous), 2^16);
end