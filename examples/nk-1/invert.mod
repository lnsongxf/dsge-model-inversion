var y pi i;

varexo e_y e_pi e_i;

parameters a1 a2 a3 b1 b2 b3 c1 c2 c3;

a1 = .2;
a2 = .8;
a3 = .05;

b1 = .3;
b2 = .7;
b3 = .1;

c1 = 0.9;
c2 = 1.5;
c3 = 0.5;

model(bytecode);
  y  = a1*y(-1) + a2*y(1) - a3*(i-pi(1)) + e_y ;
  pi = b1*pi(-1) + b2*pi(1) + b3*y + e_pi ;
  i  = c1*i(-1) + c2*pi(1) + c3*y + e_i ;
end;

steady;

check;

shocks;
var e_y  = 0.002;
var e_pi = 0.004;
var e_i  = 0.001;
end;

// Set the periods where some of the endogenous variables will be constrained.
subsample = 2Y:100Y;

// Load all the data generated by simulate.mod
SimulatedData = dseries('truedata.mat');

// Set the constrained paths for the endogenous variables.
constrainedpaths = SimulatedData{'y','pi','i'}(subsample);

/* REMARKS
**
** In this example we constrain all the endogenous variables from 2Y to 100Y to match the same variables as given by simulated.mod.
** When we invert the model, we search the sequence of innovations that leads to these realizations of the endogenous variables. If
** the model is the same, the sequence of innovations returned by the inversion routine has to match the true sequence of shocks (used
** in simulated.mod and available for reference in SimulatedData dseries object). In this example, we invert the model with a slightly
** different model by removing the max operator in the Taylor rule. Because of this difference, the innovations returned by the inversion
** routine are not equal to the true innovations. We expect the difference on e_y and e_pi to be small, and the difference on e_i much larger
** when the economy hits the ZLB (in this situation the solver compensate the absence of the max operator in the Taylor equation with a greater
** value of e_i, compared to the true value, to keep the economy on the ZLB).
**
*/

// Set the instruments (innovations used to control the paths for the endogenous variables).
exogenousvariables = dseries(NaN(99, 3), 2Y, {'e_y';'e_pi';'e_i'});

/* REMARKS
**
** We need as many instruments as contrained endogenous variables. There is no association of these innovations with the constrained
** endogenous variables. The instruments are identified by a NaN value for the exogenous variables. In this example all the exogenous
** variables are used as instruments.
**
*/

// Invert the model by calling the model_inversion routine.
[endogenousvariables, exogenousvariables] = model_inversion(constrainedpaths, exogenousvariables, SimulatedData, M_, options_, oo_);

/* REMARKS
**
** Output arguments endogenousvariables and exogenousvariables are dseries objects.
**
** In this example we constrain all the endogenous variables, so the variables in the first output argument matches exactly the
** constraints given in inputs. If we constrained only a subset of the variables we would have more variables in the first output
** argument than in the first input argument (constrainedpaths). Obviously the additional endogenous variables, ie the unconstrained
** endogenous variables, depend on the constraints given in the first input argument. The second output argument contains the
** exogenous variables consistent with the constraints defined in the first input argument. In this example, we have as many shocks for
** controlling the endogenous variables than shocks in the model.
**
*/


// Check that all the constraints are satisfied.
if max(abs(endogenousvariables.y(subsample).data-SimulatedData.y(subsample).data))>1e-6 || max(abs(endogenousvariables.pi(subsample).data-SimulatedData.pi(subsample).data))>1e-6 || max(abs(endogenousvariables.i(subsample).data-SimulatedData.i(subsample).data))>1e-6
   error('Constrained on endogenous variable paths are not all satisfied!')
end

// Plot the differences on e_y (shock in the Euler equation)
figure(1)
plot(exogenousvariables.e_y-SimulatedData.e_y) % Not zero because of the misspecification related to the ZLB
title('e_y')

// Plot the differences on e_pi (shock in the Phillips curve)
figure(2)
plot(exogenousvariables.e_pi-SimulatedData.e_pi) % Not zero because of the misspecification related to the ZLB
title('e_pi')

// Plot the differences on e_ik (shock in the Taylor rule)
// The red bullets correpond the ZLB episodes.
figure(3)
plot(exogenousvariables.e_i-SimulatedData.e_i) % Not zero because of the misspecification related to the ZLB
title('e_i')
hold on
id = find(endogenousvariables.i.data==-.05);
plot(id, zeros(1,length(id)), 'or')
hold off