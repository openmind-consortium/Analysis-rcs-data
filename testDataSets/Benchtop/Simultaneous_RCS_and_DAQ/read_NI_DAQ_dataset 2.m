%% Script to read DAQ data and make a simple plot

dataPath = 'pathToCSV.csv';
dataTable = readtable(dataPath);

firstCol = dataTable.waveform;
secondCol = str2double(dataTable.Voltage);

timeTable = cell2table(firstCol(4:end));
time = datetime(timeTable.Var1,'InputFormat','MM/dd/yyyy HH:mm:ss.SSSSSS');
voltageVolt = secondCol(4:end);

plot(time,voltageVolt)
ylabel('volatge (V)')
xlabel('time (datetime, ms resol)')