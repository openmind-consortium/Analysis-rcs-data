function unifiedTimes = unifyTime_KS(outdat)

idxpackets = find(outdat.timestamp~=0);
timestamps = outdat.timestamp(idxpackets);
systemTick = outdat.systemTick(idxpackets);

delta_time_unit_scale = 10000;

unifiedTimes = unifyTimestamps(timestamps, systemTick);



%% Subfunctions

    function currentDelta = deltaTime(systemTick_previous, systemTick_next)
        % Returns the difference between systemTick_next and
        % systemTick_previous, assuming systemTick_next comes after
        % systemTick_previous; a 'circular calculator' for systemTick
        currentDelta = mod((systemTick_next + (2^16) - systemTick_previous), 2^16);
    end

    function beforeDeltaTime = withinDeltaTime(systemTick_toTest, target_systemTick)
        % Returns 'true' if systemTick_toTest is within delta_time_unit_scale of
        % target_systemTick and target_systemTick is after systemTick_toTest
        beforeDeltaTime = deltaTime(systemTick_toTest, target_systemTick) <= delta_time_unit_scale;
    end

    function unifiedTimes = unifyTimestamps(timestamps, systemTick)
        % Returns a list of unified times, given pairs of timestamps and
        % systemTicks; timestamps measured in seconds, systemTicks measured in
        % 1e-4 seconds
        
        timestamp0 = timestamps(1);
        systemTick0 = systemTick(1);
        
        min_delta_systemTick = 0;
        max_delta_systemTick = 0;
        
        % Each sample observed allows us to bring in our error bounds
        for iTime = 1:length(timestamps)
            % For each timestamp, create a systemTick_base, which
            % conceptually allows for all points to be plotted in an
            % interval around ts0
            
            % For a given systemTick, determine the distance (along the
            % number line) from the base
            test_systemTick_base = systemTick0 + (timestamps(iTime) - timestamp0) * delta_time_unit_scale;

            % test_systemTick_base could be negative if timestamps out of
            % order
            while test_systemTick_base < 0
                test_systemTick_base = test_systemTick_base + 2^16;
            end
            
            test_systemTick_base = mod(test_systemTick_base, 2^16);
            
            dist_from_base = deltaTime(test_systemTick_base, systemTick(iTime));
            
            if dist_from_base < delta_time_unit_scale
                max_delta_systemTick = max(max_delta_systemTick, dist_from_base);
            else
                dist_to_base = deltaTime(systemTick(iTime), test_systemTick_base);
                %                 assert(dist_to_base <= delta_time_unit_scale,'dist_to_base: %s', num2str(dist_to_base)) 
                min_delta_systemTick = max(dist_to_base, min_delta_systemTick);
            end
        end
        
        toPrint = sprintf('Min delta: %s', num2str(min_delta_systemTick));
        disp(toPrint)
        toPrint = sprintf('Max delta: %s', num2str(max_delta_systemTick));
        disp(toPrint)
        
        error = delta_time_unit_scale - (min_delta_systemTick + max_delta_systemTick);
        
        fprintf('Error: %s', num2str(error));
        
        % Now we know the shift required to align the (timestamp,
        % systemTick) pairs so that they have a common zero point. This
        % allows us to create unifiedTimes.
        unifiedTimes = [];
        for iTime = 1:length(timestamps)
            systemTick_base = systemTick0 + (timestamps(iTime) - timestamp0) * delta_time_unit_scale - min_delta_systemTick;
            while systemTick_base < 0
                systemTick_base = systemTick_base + 2^16;
            end
            systemTick_base = mod(systemTick_base, 2^16);
            %             assert(withinDeltaTime(systemTick_base, systemTick(iTime)),...
            %                 'systemTick_base: %s, systemTick: %s, timestamp: %s', num2str(systemTick_base), num2str(systemTick(iTime)), num2str(timestamps(iTime)));
            systemTick_dist = deltaTime(systemTick_base, systemTick(iTime));
            
            % Theoretically, the systemTick_dist should never exceed
            % delta_time_unit_scale. However, this is observed (indicating
            % that there is impercision in systemTick and/or timestamp. To
            % accomodate this, do not assign packet times in cases where
            % systemTick_dist is creater than delta_time_unit_scale.
            % Subsequently, will reject these as bad packets.
            if systemTick_dist >= delta_time_unit_scale
                unifiedTimes(iTime) = NaN;
            else
                unifiedTimes(iTime) = timestamps(iTime) * delta_time_unit_scale + systemTick_dist;
            end
        end
    end
end

