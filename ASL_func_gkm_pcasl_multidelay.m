function mm = ASL_func_gkm_pcasl_multidelay(cbf,att,casl_dur,plds,assum_paras)
% Purpose: This is based on ASL genetic kinetic model (1 compartment).
%          Here, we assume T1app = T1b
% Input:
%	cbf      -- parameter of the function, must have 2 element
%   bat      -- bolus arrival time
%   casl_dur -- labeling duration
%	plds     -- input vector post-labeling-delay
%	assum_paras -- contains 3 assumptions: t1_blood, part_coef, labl_eff
% Output:
%	mm       -- corresponding function value
% Author: Hongli Fan
% Date:   10/20/2017

t1_blood    = assum_paras.t1_blood;
part_coef   = assum_paras.part_coef;
labl_eff    = assum_paras.labl_eff;

% t1app   = 1/(1/t1tissue + cbf/lambda); % assumption
t1_app   = t1_blood; % assumption

const   = 2 * labl_eff * cbf * t1_app / part_coef / 6000;

w1      = plds(         (plds + casl_dur) <  att                 )';
w2      = plds(logical(((plds + casl_dur) >= att).*(plds <  att)))';
w3      = plds(                                     plds >= att  )';

m1      = w1 * 0;
m2      = exp(      0 /t1_app) - exp((att-casl_dur-w2)/t1_app);
m3      = exp((att-w3)/t1_app) - exp((att-casl_dur-w3)/t1_app);
m2      = const * exp(-att/t1_blood) * m2;
m3      = const * exp(-att/t1_blood) * m3;
mm      = [m1, m2, m3]';

