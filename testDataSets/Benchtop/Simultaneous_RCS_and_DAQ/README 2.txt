These datasets include simultaneous benchtop RC+S recordings and NI DAQ 

Stimulation Parameters used in benchtop RC+S recording
stim rate = 7 Hz
stim amplitude = 7 mA
stim pulse width = 100 us (active recharge)

Measurement resistor topology between Stim Output and DAQ voltage analog input
Resistor = 2 Kohm
Voltage = 7 mA x 2 Kohm = 14 Volt
Sampling Rate DAQ = 50 KSPS
Number samples measured = 10 x 50 KSPS (10 seconds)

The duration of the file is not controlled, it starts before recording with DAQ starts and stops a while after DAQ recording finishes

Recording sessions in RCS software (1 per sampling rate)
250Hz
500Hz
1000Hz

The script 'read_NI_DAQ_dataset' can be used to parse the csv files containing data from the DAQ -- user must edit 'dataPath'