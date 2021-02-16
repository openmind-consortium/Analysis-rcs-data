N = 5000;
r = rand(1,N);
r = round(r,10);
r(:) = r(1);
elapsed_time = zeros(1,N);
elapsed_time2 = zeros(1,N);


%20000 numbers takse 430 us
%250 us to parse
%112 us to convert to numbers

for i = 100:100:N
   str = jsonencode(r(1:i)); 
   str2 = json.utils.addBuffer(uint8(str));
   %str = uint8(str);
   t = 0;
   t2 = 0;
   for j = 1:1000
       data = turtle_json_mex(str2,'raw_string',true);
       %data = turtle_json_mex(str,'raw_string',true);
       temp = json.utils.getPerformanceLog(data,true);
       t = t + temp.time__number_parsing_time;
       t2 = t2 + temp.time__total_elapsed_time_mex;
   end
   elapsed_time(i) = t;
   elapsed_time2(i) = t2;
end

close all
subplot(2,1,1)
plot(elapsed_time)
subplot(2,1,2)
plot(elapsed_time2)