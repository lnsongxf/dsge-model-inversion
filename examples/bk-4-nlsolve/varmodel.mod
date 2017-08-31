// --+ options: stochastic +--

/* © 2017 Stéphane Adjemian <stephane.adjemian@univ-lemans.fr>
 *
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * It is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the file.  If not, see <http://www.gnu.org/licenses/>.
 */

var y1 y2 y3 ;

varexo e1 e2 e3 u1 u2 u3 ;

parameters a11 a12 a13 a21 a22 a23 a31 a32 a33 b11 b12 b13 b22 b23 b33 ;

/*
** Simulate the elements of the first order autoregressive matrix (we impose stability of the model, note that
** inversion fails if the model is explosive, ie the autoregressive matrix has at least one root greater than
** one in modulus) probably because of the propagation of roundoff errors.
*/

D = diag([.9 .7 .8]);
P = randn(3,3);
A = P*D*inv(P);

a11 = A(1,1);
a12 = A(1,2);
a13 = A(1,3);
a21 = A(2,1);
a22 = A(2,2);
a23 = A(2,3);
a31 = A(3,1);
a32 = A(3,2);
a33 = A(3,3);
b11 =  .10;
b12 = -.30;
b13 =  .05;
b22 =  .20;
b23 = -.05;
b33 =  .10;

model;
    y1 = a11*y1(-1) + a12*y2(-1) + a13*y3(-1) + b11*e1 + b12*e2 + b13*e3 + u1 ;
    y2 = a21*y1(-1) + a22*y2(-1) + a23*y3(-1)          + b22*e2 + b23*e3 + u2 ;
    y3 = a31*y1(-1) + a32*y2(-1) + a33*y3(-1)                   + b33*e3 + u3 ;
end;

histval;
    y1(0) = 0;
    y2(0) = 0;
    y3(0) = 0;
end;

shocks;
    var e1 = 1.0;
    var e2 = 1.0;
    var e3 = 1.0;
    var u1 =  .1;
    var u2 =  .3;
    var u3 =  .2;
end;

steady;

check;

TrueData = simul_backward_model([], 200, options_, M_, oo_);

// Set the periods where some of the endogenous variables will be constrained.
subsample = 2Y:100Y;

// Load all the data generated by simulate.mod
SimulatedData = [dseries(TrueData.endo_simul', 1Y, cellstr(M_.endo_names)), dseries(TrueData.exo_simul, 1Y, cellstr(M_.exo_names))];

// Set the constrained paths for the endogenous variables (Output and PhysicalCapitalStock).
constrainedpaths = SimulatedData{'y1','y2','y3'}(subsample);

// Set the instruments (innovations used to control the paths for the endogenous variables).
exogenousvariables = dseries([NaN(100, 3) TrueData.exo_simul(1:100,4:6)], 1Y, {'e1';'e2';'e3';'u1';'u2';'u3'});

/* REMARK
**
** Here we will control y1, y2, and y3 with  e1, e2 and e3, u1, u2 and u3 are treated as observed
** exogenous variables. 
*/

// Invert the model by calling the model_inversion routine.
[endogenousvariables, exogenousvariables] = model_inversion(constrainedpaths, exogenousvariables, SimulatedData, M_, options_, oo_);

// Check that all the constraints are satisfied.
if max(abs(constrainedpaths(subsample).y1.data-endogenousvariables(subsample).y1.data))>1e-12
   error('Constraint on y1 path is not satisfied!')
end

if max(abs(constrainedpaths(subsample).y2.data-endogenousvariables(subsample).y2.data))>1e-12
   error('Constraint on y2 path is not satisfied!')
end

if max(abs(constrainedpaths(subsample).y3.data-endogenousvariables(subsample).y3.data))>1e-12
   error('Constraint on y3 path is not satisfied!')
end

if max(abs(exogenousvariables(subsample).u1.data-SimulatedData(subsample).u1.data))>1e-12
   error('Constraint on u1 path is not satisfied!')
end

if max(abs(exogenousvariables(subsample).u2.data-SimulatedData(subsample).u2.data))>1e-12
   error('Constraint on u2 path is not satisfied!')
end

if max(abs(exogenousvariables(subsample).u3.data-SimulatedData(subsample).u3.data))>1e-12
   error('Constraint on u3 path is not satisfied!')
end

// Check consistency of the results.
if max(abs(exogenousvariables(subsample).e1.data-SimulatedData(subsample).e1.data))>1e-12
   error('Model inversion is not consistent with true innovations (e1)')
end

if max(abs(exogenousvariables(subsample).e2.data-SimulatedData(subsample).e2.data))>1e-12
   error('Model inversion is not consistent with true innovations (e3)')
end

if max(abs(exogenousvariables(subsample).e3.data-SimulatedData(subsample).e3.data))>1e-12
   error('Model inversion is not consistent with true innovations (e3)')
end