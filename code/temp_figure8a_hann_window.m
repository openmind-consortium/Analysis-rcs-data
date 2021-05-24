function temp_plot_figure_hann_window(L)


hw100 = hannWindow(L,'100% Hann');
hw50 = hannWindow(L,'50% Hann');
hw25 = hannWindow(L,'25% Hann');

fig1 = figure;
hold on
plot(hw100,'LineWidth',2)
plot(hw50,'LineWidth',2)
plot(hw25,'LineWidth',2)

axis tight
title('Hann Window')
legend('100%','50%','25%')
ylabel('Amplitude')
xlabel('Samples')
set(gca,'FontSize',14)

savedir = '/Users/juananso/Dropbox (Personal)/Work/UCSF/starrlab_local/2.Reporting/Manuscripts/DBS Think Tank/Figures';
firname = 'Figure8a'
saveas(fig1,fullfile(savedir,firname),'epsc')

end