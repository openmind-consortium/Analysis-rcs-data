function detector = calc_lda(input,weights,norm_const,Threshold)
% function lda_outputs = calc_lda(input,weights,norm_const,Threshold)

% detector should be as long as input

       norm_x= (input - norm_const.a) .* norm_const.b;

        detector = -(norm_x * weights' - Threshold);
     

 

end